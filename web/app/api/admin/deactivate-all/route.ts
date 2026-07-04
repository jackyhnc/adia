// Admin endpoint: remove ALL machine activations for a license key in one call.
// Useful for lost/stolen machine scenarios where the user can't identify individual machines.
// POST { key } → { ok, key, removedCount }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, removeAllActivations, insertAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'deactivate-all');
  if (denied) return denied;
  const body = await req.json().catch(() => null);
  if (!body?.key) {
    return NextResponse.json({ error: 'missing key' }, { status: 400 });
  }
  const key = String(body.key).trim().toUpperCase();
  const license = await findLicense(key);
  if (!license) {
    return NextResponse.json({ error: 'unknown key' }, { status: 404 });
  }
  const removedCount = await removeAllActivations(key);
  await insertAuditLog({ licenseKey: key, action: 'deactivate_all', detail: { removedCount } });
  return NextResponse.json({ ok: true, key, removedCount });
}
