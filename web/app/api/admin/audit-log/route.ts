// Admin: list recent admin audit log entries.
// GET ?limit=N&key=ADIA-... (both optional)
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { listAdminAuditLog } from '@/lib/store';

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

  const key = req.nextUrl.searchParams.get('key') ?? undefined;
  const rawLimit = req.nextUrl.searchParams.get('limit');
  const limit = rawLimit ? Number(rawLimit) : 100;

  if (!Number.isInteger(limit) || limit < 1 || limit > 500) {
    return NextResponse.json(
      { error: 'limit must be an integer between 1 and 500' },
      { status: 400 },
    );
  }

  const entries = await listAdminAuditLog({ key, limit });
  return NextResponse.json({ entries, count: entries.length });
}
