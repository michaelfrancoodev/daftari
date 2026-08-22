import { NextResponse } from "next/server"

/**
 * Accepts one capture from the sync queue (see Flutter build docs, Part 10:
 * SyncQueue). The capture id is the idempotency key: a retry after a timeout
 * that actually succeeded must not create a duplicate, so a second POST with
 * an id already seen returns 409 rather than writing again.
 *
 * This demo keeps the seen-id set in memory, which resets on every cold
 * start — enough to prove the idempotency contract the device relies on.
 * Replace the Set with a real table (captures.id as primary key) the day a
 * database integration is connected; the endpoint contract does not change.
 */
const seen = new Set<string>()

interface CapturePayload {
  id?: string
  occurredAt?: string
  text?: string
  source?: string
  language?: string
}

export async function POST(request: Request) {
  let body: CapturePayload
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: "invalid_json" }, { status: 400 })
  }

  const { id, occurredAt, text, source, language } = body
  if (!id || !occurredAt || !text || !source || !language) {
    return NextResponse.json({ error: "missing_field" }, { status: 400 })
  }

  if (seen.has(id)) {
    // Already have it. Success from the device's point of view.
    return new NextResponse(null, { status: 409 })
  }

  seen.add(id)
  console.log("[v0] capture received", { id, source, language, length: text.length })

  return new NextResponse(null, { status: 201 })
}
