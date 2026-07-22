import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"
import * as jose from "npm:jose@5.9.6"

interface SendRequest {
  userId?: string
  token?: string
  role?: string
  title: string
  body: string
  data?: Record<string, string>
}

function getSupabase() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  )
}

async function resolveTokens(payload: SendRequest): Promise<string[]> {
  if (payload.token) return [payload.token]
  if (payload.role) {
    const supabase = getSupabase()
    const { data: users } = await supabase
      .from("users")
      .select("id")
      .eq("role", payload.role)
    const ids = (users ?? []).map((u: { id: string }) => u.id)
    if (ids.length === 0) return []
    const { data: rows } = await supabase
      .from("fcm_tokens")
      .select("token")
      .in("user_id", ids)
    return (rows ?? []).map((r: { token: string }) => r.token)
  }
  if (payload.userId) {
    const supabase = getSupabase()
    const { data: rows } = await supabase
      .from("fcm_tokens")
      .select("token")
      .eq("user_id", payload.userId)
    return (rows ?? []).map((r: { token: string }) => r.token)
  }
  return []
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    })
  }

  const payload = await req.json() as SendRequest

  if (!payload.title || !payload.body) {
    return new Response(JSON.stringify({ error: "title and body are required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }

  const tokens = await resolveTokens(payload)

  if (tokens.length === 0) {
    return new Response(JSON.stringify({ error: "No FCM tokens found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    })
  }

  const serviceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!)
  const privateKey = await jose.importPKCS8(serviceAccount.private_key, "RS256")

  const now = Math.floor(Date.now() / 1000)
  const jwt = await new jose.SignJWT({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .sign(privateKey)

  const tokenResp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  })

  if (!tokenResp.ok) {
    return new Response(JSON.stringify({ error: "Failed to send push notification" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }

  const { access_token } = await tokenResp.json()
  const supabase = getSupabase()

  const results = await Promise.allSettled(
    tokens.map(async (token) => {
      const message = {
        message: {
          token,
          notification: { title: payload.title, body: payload.body },
          data: payload.data ?? {},
        },
      }

      const resp = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(message),
        },
      )

      if (!resp.ok) {
        const errBody = await resp.text()
        if (resp.status === 404 || resp.status === 400) {
          try {
            const errJson = JSON.parse(errBody)
            const codes = errJson.error?.details?.map((d: { errorCode?: string }) => d.errorCode) ?? []
            if (codes.some((c: string) => c === "UNREGISTERED" || c === "NOT_FOUND")) {
              await supabase.from("fcm_tokens").delete().eq("token", token)
            }
          } catch { /* ignore parse errors */ }
        }
        throw new Error(`FCM error ${resp.status}: ${errBody}`)
      }

      return resp.json()
    }),
  )

  const sent = results.filter((r) => r.status === "fulfilled").length
  const failed = results.filter((r) => r.status === "rejected").length

  if (failed > 0) {
    console.error(`FCM send: ${sent} sent, ${failed} failed`)
  }

  return new Response(JSON.stringify({ sent, failed, total: tokens.length }), {
    status: failed > 0 && sent === 0 ? 500 : 200,
    headers: { "Content-Type": "application/json" },
  })
})
