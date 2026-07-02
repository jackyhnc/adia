// Admin: change the email address on a license without requiring the old email for auth.
// POST body: { key: "ADIA-...", newEmail: "new@example.com" }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use when a customer changed their primary email and can no longer authenticate
// with their old address to use the self-service /api/license/transfer route.
// Unlike /api/license/transfer this requires no old-email proof — admin is
// asserting the identity change has been verified out-of-band.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, transferLicense } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const body = await req.json().catch(() => null);
  const rawKey = body?.key ? String(body.key).trim().toUpperCase() : null;
  const rawEmail = body?.newEmail ? String(body.newEmail).trim().toLowerCase() : null;

  if (!rawKey) {
    return NextResponse.json({ error: 'missing key in body' }, { status: 400 });
  }
  if (!rawEmail) {
    return NextResponse.json({ error: 'missing newEmail in body' }, { status: 400 });
  }
  if (!EMAIL_RE.test(rawEmail)) {
    return NextResponse.json({ error: 'newEmail is not a valid email address' }, { status: 400 });
  }

  const license = await findLicense(rawKey);
  if (!license) {
    return NextResponse.json({ error: 'unknown license key' }, { status: 404 });
  }

  const oldEmail = license.email;

  if (oldEmail === rawEmail) {
    return NextResponse.json(
      { error: 'newEmail is the same as the current email — no change made' },
      { status: 422 },
    );
  }

  await transferLicense(rawKey, rawEmail);

  return NextResponse.json({
    ok: true,
    key: rawKey,
    oldEmail,
    newEmail: rawEmail,
    plan: license.plan,
  });
}
