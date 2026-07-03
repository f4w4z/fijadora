import "jsr:@supabase/functions-js/edge-runtime.d.ts"

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
const MODEL = Deno.env.get('OPENROUTER_MODEL') ?? 'google/gemini-2.0-flash-lite-001'

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { 'Content-Type': 'application/json' } })
  }

  if (!OPENROUTER_API_KEY) {
    return new Response(JSON.stringify({ error: 'OPENROUTER_API_KEY not configured' }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }

  try {
    const { model, messages, maxTokens = 512 } = await req.json()

    const resp = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://phoebe.app',
        'X-Title': 'Phoebe',
      },
      body: JSON.stringify({
        model: model ?? MODEL,
        messages,
        max_tokens: maxTokens,
        response_format: { type: 'json_object' },
      }),
    })

    const data = await resp.json()
    return new Response(JSON.stringify(data), {
      status: resp.status,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : 'Internal error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
