// Self-service: re-send license key(s) to an email address.
// POST body: { email: "user@example.com" }
//
// Always returns { ok: true } regardless of whether the email exists — this
// prevents email enumeration attacks. If licenses are found, a summary email
// is sent. Rate-limited to 3 requests per 15 minutes per IP.

import { NextRequest, NextResponse } from 'next/server';
import { findLicensesByEmail } from '@/lib/store';
import { sendLicenseResendEmail } from '@/lib/email';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const rl = rateLimit(`resend:${clientIp(req)}`, 3, 900);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }

  const body = await req.json().catch(() => null);
  const raw = String(body?.email ?? '').trim().toLowerCase();
  if (!/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(raw)) {
    return NextResponse.json({ error: 'Invalid email.' }, { status: 400 });
  }

  const licenses = await findLicensesByEmail(raw);

  if (licenses.length > 0) {
    // Include all licenses so the user can see exactly what they own.
    await sendLicenseResendEmail(raw, licenses.map((l) => ({
      key: l.key,
      plan: l.plan,
      status: l.status,
    })));
  }

  // Always return ok=true — no enumeration.
  return NextResponse.json({ ok: true });
}
