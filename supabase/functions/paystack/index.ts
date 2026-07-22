import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

const PAYSTACK_SECRET = Deno.env.get("PAYSTACK_SECRET_KEY")
const MOCK = !PAYSTACK_SECRET
const BASE = "https://api.paystack.co"

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
        // amount is in kobo (smallest currency unit)
        const { email, amount, reference, orderId, callbackUrl } = payload
        const { ok, status, data } = await paystackFetch("/transaction/initialize", "POST", {
          email,
          amount,
          reference,
          callback_url: callbackUrl,
          metadata: { orderId },
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
        // Persist payment result into paystack_payments ledger.
        const supabase = getSupabase()
        const d = data.data
        await supabase.from("paystack_payments").upsert({
          reference: d.reference,
          amount: d.amount / 100,
          currency: d.currency ?? "NGN",
          status: d.status === "success" ? "success" : (d.status ?? "pending"),
          gateway_response: d.gateway_response,
          customer_id: d.customer?.id ?? null,
          paid_at: d.paid_at ?? null,
        }, { onConflict: "reference" })

        // If paid and linked to an order, mark order paid.
        if (d.status === "success") {
          const orderId = d.metadata?.orderId
          if (orderId) {
            await supabase.from("orders").update({
              status: "paid",
              paystack_reference: d.reference,
              paystack_paid_at: d.paid_at ?? new Date().toISOString(),
            }).eq("id", orderId)
          }
        }
        return new Response(JSON.stringify(data.data), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      }

      case "create_recipient": {
        const { name, accountNumber, bankCode, currency } = payload
        const { ok, status, data } = await paystackFetch("/transferrecipient", "POST", {
          type: "nuban",
          name,
          account_number: accountNumber,
          bank_code: bankCode,
          currency: currency ?? "NGN",
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
        const { amount, recipientCode, reference } = payload
        const { ok, status, data } = await paystackFetch("/transfer", "POST", {
          source: "balance",
          amount,
          recipient: recipientCode,
          reference,
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

        const recipient = await paystackFetch("/transferrecipient", "POST", {
          type: "nuban",
          name,
          account_number: accountNumber,
          bank_code: bankCode,
          currency: "NGN",
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
          .update({ status: "processing", paystack_recipient_code: recipientCode })
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
      const { reference, orderId } = payload
      return new Response(JSON.stringify({
        mock: true,
        authorization_url: `app://mock-paystack?reference=${reference}&orderId=${orderId ?? ""}`,
        access_code: "mock_access_code",
        reference,
      }), { status: 200, headers: { "Content-Type": "application/json" } })
    }

    case "verify": {
      const { reference } = payload
      const orderId = (payload.orderId as string) ?? null
      await supabase.from("paystack_payments").upsert({
        reference,
        amount: 0,
        currency: "NGN",
        status: "success",
        gateway_response: "Mock mode — auto approved",
        paid_at: new Date().toISOString(),
      }, { onConflict: "reference" })
      if (orderId) {
        await supabase.from("orders").update({
          status: "paid",
          paystack_reference: reference,
          paystack_paid_at: new Date().toISOString(),
        }).eq("id", orderId)
      }
      return new Response(JSON.stringify({
        mock: true,
        status: "success",
        reference,
        amount: 0,
        currency: "NGN",
        gateway_response: "Mock mode — auto approved",
        paid_at: new Date().toISOString(),
        metadata: { orderId },
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
        .update({ status: "processing", paystack_recipient_code: `mock_recipient_${Date.now()}` })
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
