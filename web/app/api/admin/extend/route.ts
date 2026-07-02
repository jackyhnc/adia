// Admin: extend a license's expiresAt by N days.
// POST body: { key: "ADIA-...", days: number }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Goodwill extension after a payment dispute or billing hiccup
//   - Compensation extension for downtime
//   - Manual grace period without going through Stripe
//
// If expiresAt is null (lifetime) or in the past, extends from now.
// If expiresAt is in the future, extends from that date.
// No status gate — admin can extend regardless of license status.
// days must be a positive integer; max 3650 (10 years) to prevent typos.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setExpiry } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_DAYS = 3650;

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

export async function POST(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }
  const body = await req.json().catch(() => null);
  const rawKey = body?.key;
  if (!rawKey) return NextResponse.json({ error: 'missing key in body' }, { status: 400 });
  const key = String(rawKey).trim().toUpperCase();

  const rawDays = body?.days;
  if (rawDays === undefined || rawDays === null) {
    return NextResponse.json({ error: 'missing days in body' }, { status: 400 });
  }
  const days = Number(rawDays);
  if (!Number.isInteger(days) || days < 1) {
    return NextResponse.json({ error: 'days must be a positive integer' }, { status: 400 });
  }
  if (days > MAX_DAYS) {
    return NextResponse.json(
      { error: `days must be ≤ ${MAX_DAYS} (10 years)` },
      { status: 400 },
    );
  }

  const license = await findLicense(key);
  if (!license) return NextResponse.json({ error: 'unknown key' }, { status: 404 });

  const previousExpiresAt = license.expiresAt ?? null;

  // Extend from the later of "now" or the current expiresAt, so a past
  // expiry doesn't produce a new date that's still in the past.
  const now = new Date();
  const baseDate =
    previousExpiresAt && new Date(previousExpiresAt) > now
      ? new Date(previousExpiresAt)
      : now;
  baseDate.setDate(baseDate.getDate() + days);
  const newExpiresAt = baseDate.toISOString();

  await setExpiry(key, newExpiresAt);

  return NextResponse.json({ ok: true, key, previousExpiresAt, newExpiresAt, days });
}
