// Admin: reactivate a license that was previously revoked, expired, or past_due.
// POST body: { key: "ADIA-...", note?: string }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Wrongly revoked license (admin error)
//   - Customer's payment failure was resolved manually outside Stripe
//   - Customer is granted goodwill reinstatement
//
// Sets status to 'active'. Does not alter expiresAt or stripeSub — caller is
// responsible for updating those separately if needed.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setStatus } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

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
  const license = await findLicense(key);
  if (!license) return NextResponse.json({ error: 'unknown key' }, { status: 404 });
  if (license.status === 'active') {
    return NextResponse.json(
      { error: 'license is already active', key, status: 'active' },
      { status: 422 },
    );
  }
  const previousStatus = license.status;
  await setStatus(key, 'active');
  return NextResponse.json({ ok: true, key, previousStatus, newStatus: 'active' });
}
