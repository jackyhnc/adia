// Admin: list admin audit log entries.
// GET ?key=ADIA-...&limit=100 → [{ id, licenseKey, action, detail, createdAt }]
//   key: optional — if provided, filters to entries for that license key.
//   limit: optional — max 500, default 100.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { listAuditLog } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

export async function GET(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }
  const rawKey = req.nextUrl.searchParams.get('key');
  const rawLimit = req.nextUrl.searchParams.get('limit');
  const licenseKey = rawKey ? rawKey.trim().toUpperCase() : undefined;
  const limit = rawLimit ? Math.min(Math.max(1, Number(rawLimit) || 100), 500) : 100;
  const entries = await listAuditLog({ licenseKey, limit });
  return NextResponse.json({ count: entries.length, entries });
}
