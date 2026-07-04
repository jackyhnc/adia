// Admin: send a custom email to a license holder.
// POST body: { key: string, subject: string, message: string }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Reach out about a billing issue or policy change
//   - Warn a user about suspected abuse before revoking
//   - Send a personalised onboarding or winback message
//
// Rate-limited at 10 req/60 s (tighter than other admin routes) because this
// sends real email. Key must exist in the database; subject max 200 chars;
// message max 2000 chars. Writes a `notify` audit log entry on success.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, insertAuditLog } from '@/lib/store';
import { sendCustomEmail } from '@/lib/email';
import { adminGuard } from '@/lib/admin';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const SUBJECT_MAX = 200;
const MESSAGE_MAX = 2000;

export async function POST(req: NextRequest) {
  // Tighter email-send rate limit (10 req/60 s) on a separate bucket from the
  // adminGuard auth check bucket so the two limiters don't share tokens.
  const rl = rateLimit(`notify-email:${clientIp(req)}`, 10, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }

  const denied = adminGuard(req, 'notify');
  if (denied) return denied;

  const body = await req.json().catch(() => null);

  const rawKey = body?.key ? String(body.key).trim().toUpperCase() : null;
  if (!rawKey) {
    return NextResponse.json({ error: 'missing key in body' }, { status: 400 });
  }

  const rawSubject = body?.subject ? String(body.subject).trim() : null;
  if (!rawSubject) {
    return NextResponse.json({ error: 'missing subject in body' }, { status: 400 });
  }
  if (rawSubject.length > SUBJECT_MAX) {
    return NextResponse.json(
      { error: `subject too long — max ${SUBJECT_MAX} characters` },
      { status: 400 },
    );
  }

  const rawMessage = body?.message ? String(body.message).trim() : null;
  if (!rawMessage) {
    return NextResponse.json({ error: 'missing message in body' }, { status: 400 });
  }
  if (rawMessage.length > MESSAGE_MAX) {
    return NextResponse.json(
      { error: `message too long — max ${MESSAGE_MAX} characters` },
      { status: 400 },
    );
  }

  const license = await findLicense(rawKey);
  if (!license) {
    return NextResponse.json({ error: 'unknown license key' }, { status: 404 });
  }

  await sendCustomEmail(license.email, rawSubject, rawMessage);

  const sentAt = new Date().toISOString();
  await insertAuditLog({
    licenseKey: rawKey,
    action: 'notify',
    detail: { to: license.email, subject: rawSubject },
  });

  return NextResponse.json({ ok: true, key: rawKey, to: license.email, sentAt });
}
