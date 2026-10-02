import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

type OutboxRow = {
  id: string
  user_id: string
  actor_id: string | null
  kind: string
}

const projectId = Deno.env.get('FCM_PROJECT_ID') ?? 'bobadex'

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return json({ error: 'method not allowed' }, 405)
  }

  const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')
  const privateKey = Deno.env.get('FCM_PRIVATE_KEY')?.replace(/\\n/g, '\n')
  if (!clientEmail || !privateKey) {
    return json({ error: 'FCM credentials are not configured' }, 503)
  }

  const body = await req.json().catch(() => null)
  const id = outboxId(body)
  if (!id) return json({ error: 'missing outbox id' }, 400)

  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, serviceRoleKey())
  const { data: claimed, error: claimError } = await supabase
    .from('push_outbox')
    .update({ sent_at: new Date().toISOString() })
    .eq('id', id)
    .is('sent_at', null)
    .select('id, user_id, actor_id, kind')
    .maybeSingle()

  if (claimError) return json({ error: claimError.message }, 500)
  if (!claimed) return json({ skipped: true })

  const row = claimed as OutboxRow
  try {
    const actorName = await displayName(supabase, row.actor_id)
    const { title, body: text } = copyFor(row.kind, actorName)
    const { data: tokens, error: tokenError } = await supabase
      .from('device_push_tokens')
      .select('token')
      .eq('user_id', row.user_id)
    if (tokenError) throw new Error(tokenError.message)

    const accessToken = await fcmAccessToken(clientEmail, privateKey)
    const stale: string[] = []
    for (const item of tokens ?? []) {
      const token = item.token as string
      const staleToken = await sendFcm({
        accessToken,
        token,
        title,
        body: text,
        data: {
          kind: row.kind,
          actor_id: row.actor_id ?? '',
        },
      })
      if (staleToken) stale.push(token)
    }
    if (stale.length > 0) {
      await supabase.from('device_push_tokens').delete().in('token', stale)
    }
    return json({ sent: (tokens ?? []).length - stale.length })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'send failed'
    await supabase.from('push_outbox').update({ error: message }).eq('id', row.id)
    return json({ error: message }, 500)
  }
})

function outboxId(body: unknown): string | null {
  if (!body || typeof body !== 'object') return null
  const record = (body as { record?: { id?: unknown }; id?: unknown }).record
  const raw = record?.id ?? (body as { id?: unknown }).id
  return typeof raw === 'string' && raw.length > 0 ? raw : null
}

function serviceRoleKey(): string {
  const bundled = Deno.env.get('SUPABASE_SECRET_KEYS')
  if (bundled) {
    const parsed = JSON.parse(bundled) as Record<string, string>
    if (parsed.default) return parsed.default
    const first = Object.values(parsed).find((value) => value.length > 0)
    if (first) return first
  }
  const legacy = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (legacy) return legacy
  throw new Error('missing service role key')
}

async function displayName(
  supabase: ReturnType<typeof createClient>,
  actorId: string | null,
): Promise<string> {
  if (!actorId) return 'Someone'
  const { data } = await supabase
    .from('users')
    .select('display_name, username')
    .eq('id', actorId)
    .maybeSingle()
  const name = (data?.display_name as string | null)?.trim()
  if (name) return name
  const username = (data?.username as string | null)?.trim()
  return username ? `@${username}` : 'Someone'
}

function copyFor(kind: string, actorName: string): { title: string; body: string } {
  if (kind === 'friend_accept') {
    return {
      title: 'Friend request',
      body: `${actorName} accepted your friend request`,
    }
  }
  return {
    title: 'Friend request',
    body: `${actorName} wants to be friends`,
  }
}

async function fcmAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  const jwt = new JWT({
    email: clientEmail,
    key: privateKey,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  })
  const tokens = await jwt.authorize()
  const access = tokens?.access_token
  if (!access) throw new Error('FCM authorization failed')
  return access
}

async function sendFcm({
  accessToken,
  token,
  title,
  body,
  data,
}: {
  accessToken: string
  token: string
  title: string
  body: string
  data: Record<string, string>
}): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: { priority: 'HIGH' },
          apns: { payload: { aps: { sound: 'default' } } },
        },
      }),
    },
  )
  if (res.ok) return false
  const payload = await res.json().catch(() => null)
  const status = payload?.error?.status as string | undefined
  const details = payload?.error?.details as Array<{ errorCode?: string }> | undefined
  const unregistered = details?.some((detail) => detail.errorCode === 'UNREGISTERED')
  if (status === 'NOT_FOUND' || unregistered) return true
  throw new Error(payload?.error?.message ?? `FCM ${res.status}`)
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
