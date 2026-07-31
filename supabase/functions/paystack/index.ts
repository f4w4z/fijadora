import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

const PAYSTACK_SECRET = Deno.env.get("PAYSTACK_SECRET_KEY")
const MOCK = !PAYSTACK_SECRET
const BASE = "https://api.paystack.co"

// Fijadora bills in Ghana Cedis (GHS). Paystack amounts are in the
// smallest unit (pesewas), same ×100 convention as NGN kobo.
const CURRENCY = "GHS"

function getSupabase() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  )
}

function authHeaders() {
  return {
    "Authorization": `Bearer ${PAYSTACK_SECRET}`,
    "Content-Type": "application/json",
  }
}

async function paystackFetch(path: string, method: string, body?: unknown) {
  const resp = await fetch(`${BASE}${path}`, {
    method,
    headers: authHeaders(),
    body: body ? JSON.stringify(body) : undefined,
  })
  const data = await resp.json()
  return { ok: resp.ok, status: resp.status, data }
}

/// Persist a verified payment and route it to the right ledger:
/// - orderId  → mark the shop order paid (legacy)
/// - jobId + paymentKind=deposit      → record deposit, unlock assignment
/// - jobId + paymentKind=change_order → record delta, mark change order paid
/// - jobId + paymentKind=balance      → record balance, credit worker wallet
async function handleVerifiedPayment(
  supabase: ReturnType<typeof getSupabase>,
  payment: {
    reference: string
    amountMajor: number
    currency: string
    status: string
    gatewayResponse: string | null
    paidAt: string | null
    metadata: Record<string, unknown>
  },
  isMock = false,
) {
  const d = payment
  await supabase.from("paystack_payments").upsert({
    reference: d.reference,
    amount: d.amountMajor,
    currency: d.currency ?? CURRENCY,
    status: d.status === "success" ? "success" : (d.status ?? "pending"),
    gateway_response: d.gatewayResponse,
    customer_id: d.metadata?.customerId ?? null,
    order_id: d.metadata?.orderId ?? null,
    job_id: d.metadata?.jobId ?? null,
    paid_at: d.paidAt ?? null,
  }, { onConflict: "reference" })

  if (d.status !== "success") return

  const orderId = d.metadata?.orderId
  if (orderId) {
    await supabase.from("orders").update({
      status: "preparing",
      paystack_reference: d.reference,
      paystack_paid_at: d.paidAt ?? new Date().toISOString(),
    }).eq("id", orderId)
  }

  const jobId = d.metadata?.jobId as string | undefined
  const paymentKind = d.metadata?.paymentKind as string | undefined
  if (!jobId || !paymentKind) return

  // Record the payment in the job ledger (UNIQUE reference = idempotent)
  await supabase.from("job_payments").upsert({
    job_id: jobId,
    kind: paymentKind === "deposit" ? "deposit"
      : paymentKind === "change_order" ? "change_order"
      : "balance",
    amount: d.amountMajor,
    status: "paid",
    paystack_reference: d.reference,
  }, { onConflict: "paystack_reference" })

  if (paymentKind === "deposit") {
    const { data: job } = await supabase.from("jobs")
      .select("id")
      .eq("id", jobId)
      .eq("status", "quoted")
      .maybeSingle()
    if (job) {
      await supabase.from("jobs").update({
        payment_status: "deposit_paid",
        paystack_reference: d.reference,
      }).eq("id", jobId)
    }
  } else if (paymentKind === "change_order") {
    const changeOrderId = d.metadata?.changeOrderId as string | undefined
    if (changeOrderId) {
      await supabase.rpc("mark_change_order_paid", {
        p_job_id: jobId,
        p_change_order_id: changeOrderId,
      })
    }
  } else if (paymentKind === "balance") {
    // Atomic: ledger row + wallet credit + payment_status=paid, with an
    // amount check against this verified Paystack payment.
    await supabase.rpc("credit_job_earnings", {
      p_job_id: jobId,
      p_reference: d.reference,
    })
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    })
  }

  if (MOCK) {
    return await mockHandler(await req.json())
  }

  try {
    const payload = await req.json()
    const action = payload.action as string

    switch (action) {
      case "initialize": {
        // amount is in pesewas/kobo (smallest currency unit)
        const { email, amount, reference, orderId, jobId, paymentKind, callbackUrl } = payload
        const { ok, status, data } = await paystackFetch("/transaction/initialize", "POST", {
          email,
          amount,
          currency: CURRENCY,
          reference,
          callback_url: callbackUrl,
          metadata: { orderId, jobId, paymentKind, customerId: payload.customerId ?? null },
        })
        if (!ok) {
          return new Response(JSON.stringify({ error: data.message ?? "Initialize failed" }), {
            status,
            headers: { "Content-Type": "application/json" },
          })
        }
        return new Response(JSON.stringify(data.data), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      }

      case "verify": {
        const { reference } = payload
        const { ok, status, data } = await paystackFetch(
          `/transaction/verify/${encodeURIComponent(reference)}`,
          "GET",
        )
        if (!ok) {
          return new Response(JSON.stringify({ error: data.message ?? "Verify failed" }), {
            status,
            headers: { "Content-Type": "application/json" },
          })
        }
        const supabase = getSupabase()
        const d = data.data
        await handleVerifiedPayment(supabase, {
          reference: d.reference,
          amountMajor: d.amount / 100,
          currency: d.currency ?? CURRENCY,
          status: d.status ?? "pending",
          gatewayResponse: d.gateway_response ?? null,
          paidAt: d.paid_at ?? null,
          metadata: { ...(d.metadata ?? {}), customerId: d.customer?.id ?? null },
        })
        return new Response(JSON.stringify(data.data), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      }

      case "create_recipient": {
        const { name, accountNumber, bankCode, currency } = payload
        // Ghana settles via GHIPSS; Nigeria via NUBAN.
        const type = (currency ?? CURRENCY) === "GHS" ? "ghipss" : "nuban"
        const { ok, status, data } = await paystackFetch("/transferrecipient", "POST", {
          type,
          name,
          account_number: accountNumber,
          bank_code: bankCode,
          currency: currency ?? CURRENCY,
        })
        if (!ok) {
          return new Response(JSON.stringify({ error: data.message ?? "Recipient failed" }), {
            status,
            headers: { "Content-Type": "application/json" },
          })
        }
        return new Response(JSON.stringify({ recipientCode: data.data.recipient_code }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      }

      case "transfer": {
        const { amount, recipientCode, reference, currency } = payload
        const { ok, status, data } = await paystackFetch("/transfer", "POST", {
          source: "balance",
          amount,
          recipient: recipientCode,
          reference,
          currency: currency ?? CURRENCY,
        })
        if (!ok) {
          return new Response(JSON.stringify({ error: data.message ?? "Transfer failed" }), {
            status,
            headers: { "Content-Type": "application/json" },
          })
        }
        return new Response(JSON.stringify(data.data), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      }

      case "approve_payout": {
        // Staff releases a worker withdrawal. Requires the approval PIN
        // (set/reset by admin in the app_settings table) instead of re-entering bank details.
        const pin = payload.pin as string
        const payoutId = payload.payoutId as string
        const supabase = getSupabase()
        const { data: setting } = await supabase
          .from("app_settings")
          .select("value")
          .eq("key", "payout_approval_pin")
          .maybeSingle()
        const expectedPin = (setting?.value as string) ?? ""
        if (!expectedPin || pin !== expectedPin) {
          return new Response(JSON.stringify({ error: "Invalid approval PIN" }), {
            status: 403,
            headers: { "Content-Type": "application/json" },
          })
        }

        const { data: payout, error: poErr } = await supabase
          .from("payouts")
          .select()
          .eq("id", payoutId)
          .single()
        if (poErr || !payout) {
          return new Response(JSON.stringify({ error: "Payout not found" }), {
            status: 404,
            headers: { "Content-Type": "application/json" },
          })
        }
        if (payout.status !== "pending") {
          return new Response(JSON.stringify({ error: "Payout already processed" }), {
            status: 409,
            headers: { "Content-Type": "application/json" },
          })
        }

        const name = (payout.bank_account_name as string) ?? ""
        const accountNumber = (payout.bank_account_number as string) ?? ""
        const bankCode = (payout.bank_code as string) ?? ""
        const currency = (payout.currency as string) ?? CURRENCY
        const type = currency === "GHS" ? "ghipss" : "nuban"

        const recipient = await paystackFetch("/transferrecipient", "POST", {
          type,
          name,
          account_number: accountNumber,
          bank_code: bankCode,
          currency,
        })
        if (!recipient.ok) {
          return new Response(JSON.stringify({ error: recipient.data.message ?? "Recipient failed" }), {
            status: recipient.status,
            headers: { "Content-Type": "application/json" },
          })
        }
        const recipientCode = (recipient.data.data as { recipient_code: string }).recipient_code

        const transfer = await paystackFetch("/transfer", "POST", {
          source: "balance",
          amount: Math.round((payout.amount as number) * 100),
          recipient: recipientCode,
          reference: payout.paystack_transfer_reference,
          currency,
        })
        if (!transfer.ok) {
          return new Response(JSON.stringify({ error: transfer.data.message ?? "Transfer failed" }), {
            status: transfer.status,
            headers: { "Content-Type": "application/json" },
          })
        }

        // Mark approved + processing and deduct wallet via ledger RPC.
        await supabase.rpc("approve_payout", { p_payout_id: payoutId })
        await supabase
          .from("payouts")
          .update({ status: "preparing", paystack_recipient_code: recipientCode })
          .eq("id", payoutId)

        return new Response(JSON.stringify(transfer.data.data), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      }

      default:
        return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        })
    }
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})

// ─── Mock mode: PAYSTACK_SECRET_KEY not set ────────────────────────────────
// Simulates successful payments/transfers so the app flows end-to-end without
// a real Paystack account. The response includes `mock: true` so the app can
// skip opening a real browser and auto-confirm.
async function mockHandler(payload: Record<string, unknown>) {
  const action = payload.action as string
  const supabase = getSupabase()

  switch (action) {
    case "initialize": {
      const { reference, orderId, jobId, paymentKind } = payload
      return new Response(JSON.stringify({
        mock: true,
        authorization_url: `app://mock-paystack?reference=${reference}&orderId=${orderId ?? ""}&jobId=${jobId ?? ""}&paymentKind=${paymentKind ?? ""}`,
        access_code: "mock_access_code",
        reference,
      }), { status: 200, headers: { "Content-Type": "application/json" } })
    }

    case "verify": {
      const reference = payload.reference as string
      await handleVerifiedPayment(
        supabase,
        {
          reference,
          amountMajor: 0,
          currency: CURRENCY,
          status: "success",
          gatewayResponse: "Mock mode — auto approved",
          paidAt: new Date().toISOString(),
          metadata: {
            orderId: (payload.orderId as string) ?? null,
            jobId: (payload.jobId as string) ?? null,
            paymentKind: (payload.paymentKind as string) ?? null,
            changeOrderId: (payload.changeOrderId as string) ?? null,
          },
        },
        true,
      )
      return new Response(JSON.stringify({
        mock: true,
        status: "success",
        reference,
        amount: 0,
        currency: CURRENCY,
        gateway_response: "Mock mode — auto approved",
        paid_at: new Date().toISOString(),
        metadata: {
          orderId: (payload.orderId as string) ?? null,
          jobId: (payload.jobId as string) ?? null,
          paymentKind: (payload.paymentKind as string) ?? null,
        },
      }), { status: 200, headers: { "Content-Type": "application/json" } })
    }

    case "create_recipient": {
      return new Response(JSON.stringify({ mock: true, recipientCode: `mock_recipient_${Date.now()}` }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    }

    case "transfer": {
      const { reference } = payload
      return new Response(JSON.stringify({ mock: true, reference, status: "success" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    }

    case "approve_payout": {
      const pin = payload.pin as string
      const payoutId = payload.payoutId as string
      const { data: setting } = await supabase
        .from("app_settings")
        .select("value")
        .eq("key", "payout_approval_pin")
        .maybeSingle()
      const expectedPin = (setting?.value as string) ?? ""
      if (!expectedPin || pin !== expectedPin) {
        return new Response(JSON.stringify({ error: "Invalid approval PIN" }), {
          status: 403,
          headers: { "Content-Type": "application/json" },
        })
      }
      const { data: payout, error: poErr } = await supabase
        .from("payouts")
        .select()
        .eq("id", payoutId)
        .single()
      if (poErr || !payout) {
        return new Response(JSON.stringify({ error: "Payout not found" }), {
          status: 404,
          headers: { "Content-Type": "application/json" },
        })
      }
      if (payout.status !== "pending") {
        return new Response(JSON.stringify({ error: "Payout already processed" }), {
          status: 409,
          headers: { "Content-Type": "application/json" },
        })
      }
      await supabase.rpc("approve_payout", { p_payout_id: payoutId })
      await supabase
        .from("payouts")
        .update({ status: "preparing", paystack_recipient_code: `mock_recipient_${Date.now()}` })
        .eq("id", payoutId)
      return new Response(JSON.stringify({ mock: true, status: "success", reference: payout.paystack_transfer_reference }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    }

    default:
      return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
  }
}
