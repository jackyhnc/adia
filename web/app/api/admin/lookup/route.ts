// Admin: look up a license by key (and optional email).
// Auth: ADMIN_TOKEN bearer header. Never expose without it.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, listAuditLog } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false; // refuse rather than allow when unset
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  // Allow ?token=... fallback for quick checks from the browser.
  return req.nextUrl.searchParams.get('token') === token;
}

export async function GET(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }
  const key = req.nextUrl.searchParams.get('key');
  const email = req.nextUrl.searchParams.get('email') ?? undefined;
  if (!key) return NextResponse.json({ error: 'missing ?key=' }, { status: 400 });
  const license = await findLicense(key, email);
  if (!license) return NextResponse.json({ error: 'not found' }, { status: 404 });
  const recentAudit = await listAuditLog({ licenseKey: license.key, limit: 5 });
  return NextResponse.json({ license, recentAudit });
}
