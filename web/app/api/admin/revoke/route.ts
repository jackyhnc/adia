// Admin: manually revoke (cancel) a license key.
// POST body: { key: "ADIA-..." }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setStatus, insertAuditLog } from '@/lib/store';

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
  const previousStatus = license.status;
  await setStatus(key, 'canceled');
  await insertAuditLog({ licenseKey: key, action: 'revoke', detail: { previousStatus, newStatus: 'canceled' } });
  return NextResponse.json({ ok: true, key, previousStatus, newStatus: 'canceled' });
}
