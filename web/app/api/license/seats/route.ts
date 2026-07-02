// User-facing endpoint to list all activated machines for a license.
// GET { key, email } (query params) → { key, plan, seatCount, seats: [{machineHash, firstSeen, lastSeen}] }
// Auth: key + email (same credentials as /activate and /deactivate).
// Rate-limited: 20 req/min per IP.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, listActivations } from '@/lib/store';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const rl = rateLimit(`seats:${clientIp(req)}`, 20, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }
  const rawKey = req.nextUrl.searchParams.get('key');
  const rawEmail = req.nextUrl.searchParams.get('email');
  if (!rawKey || !rawEmail) {
    return NextResponse.json({ error: 'missing key or email' }, { status: 400 });
  }
  const license = await findLicense(rawKey, rawEmail);
  if (!license) {
    return NextResponse.json({ error: 'License key not found for that email.' }, { status: 404 });
  }
  const seats = await listActivations(license.key);
  return NextResponse.json({
    key: license.key,
    plan: license.plan,
    status: license.status,
    seatCount: seats.length,
    seats,
  });
}
