// Admin: look up a license by key (and optional email).
// Auth: ADMIN_TOKEN bearer header. Never expose without it.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, listAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'lookup');
  if (denied) return denied;
  const key = req.nextUrl.searchParams.get('key');
  const email = req.nextUrl.searchParams.get('email') ?? undefined;
  if (!key) return NextResponse.json({ error: 'missing ?key=' }, { status: 400 });
  const license = await findLicense(key, email);
  if (!license) return NextResponse.json({ error: 'not found' }, { status: 404 });
  const recentAudit = await listAuditLog({ licenseKey: license.key, limit: 5 });
  return NextResponse.json({ license, recentAudit });
}
