import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

interface Payload {
  customerId: string
  requestTitle: string
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    })
  }

  const { customerId, requestTitle } = await req.json() as Payload

  if (!customerId || !requestTitle) {
    return new Response(JSON.stringify({ error: "customerId and requestTitle are required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  )

  const { data: user, error: userError } = await supabase
    .from("users")
    .select("email, name")
    .eq("id", customerId)
    .single()

  if (userError || !user?.email) {
    console.error("Failed to resolve customer email:", userError)
    return new Response(JSON.stringify({ error: "Customer not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    })
  }

  const resendKey = Deno.env.get("RESEND_API_KEY")
  const fromEmail = Deno.env.get("RESEND_FROM_EMAIL") ?? "noreply@fijadora.com"

  if (!resendKey) {
    console.error("RESEND_API_KEY not configured")
    return new Response(JSON.stringify({ error: "Email service not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#f4f4f4;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <div style="max-width:480px;margin:40px auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.06);">
    <div style="background:linear-gradient(135deg,#1a1a2e,#16213e);padding:32px 24px;text-align:center;">
      <h1 style="color:#ffffff;margin:0;font-size:22px;font-weight:700;">Fijadora</h1>
    </div>
    <div style="padding:32px 24px;">
      <h2 style="color:#1a1a2e;margin:0 0 12px;font-size:20px;font-weight:700;">Your requested product is now available!</h2>
      <p style="color:#555;font-size:15px;line-height:1.6;margin:0 0 20px;">
        Hi ${user.name || "there"}, great news! The product you requested is now available in our shop.
      </p>
      <div style="background:#f8f8f8;border-radius:12px;padding:16px;margin-bottom:24px;">
        <p style="margin:0;color:#888;font-size:12px;text-transform:uppercase;letter-spacing:0.5px;">Requested item</p>
        <p style="margin:4px 0 0;color:#1a1a2e;font-size:16px;font-weight:600;">${requestTitle}</p>
      </div>
      <a href="https://fijadora.com" style="display:block;text-align:center;background:#1a1a2e;color:#ffffff;text-decoration:none;padding:14px 24px;border-radius:10px;font-weight:600;font-size:15px;">
        Browse the Shop
      </a>
    </div>
    <div style="padding:16px 24px;text-align:center;border-top:1px solid #f0f0f0;">
      <p style="margin:0;color:#aaa;font-size:12px;">This is an automated notification from Fijadora.</p>
    </div>
  </div>
</body>
</html>`

  const resp = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: fromEmail,
      to: [user.email],
      subject: `"${requestTitle}" is now available on Fijadora`,
      html,
    }),
  })

  if (!resp.ok) {
    const errBody = await resp.text()
    console.error("Resend error:", resp.status, errBody)
    return new Response(JSON.stringify({ error: "Failed to send email" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }

  const result = await resp.json()
  return new Response(JSON.stringify({ sent: true, id: result.id }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  })
})
