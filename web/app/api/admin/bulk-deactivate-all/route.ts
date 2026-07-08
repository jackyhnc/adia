// Admin: wipe ALL machine activations for multiple license keys in one batch.
// POST body: { keys: string[] }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use case: a cohort of customers has lost access to all their machines (e.g. after
// a company IT refresh or stolen devices) and support needs to clear seats in bulk
// rather than calling deactivate-all one key at a time.
//
// Max 100 keys per request.
// Skips not_found (unknown key) and already_clear (key exists but has 0 activations).
// Each key whose activations are actually removed gets its own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, countActivations, removeAllActivations, insertAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_KEYS = 100;

type ChangedResult = { key: string; removedCount: number };
type SkipResult = { key: string; reason: 'not_found' | 'already_clear' };

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'bulk-deactivate-all');
  if (denied) return denied;

  const body = await req.json().catch(() => null);

  const rawKeys = body?.keys;
  if (!Array.isArray(rawKeys) || rawKeys.length === 0) {
    return NextResponse.json({ error: 'missing or empty keys array in body' }, { status: 400 });
  }
  if (rawKeys.length > MAX_KEYS) {
    return NextResponse.json(
      { error: `too many keys — max ${MAX_KEYS} per request` },
      { status: 400 },
    );
  }

  const keys = rawKeys.map((k: unknown) => String(k).trim().toUpperCase());

  const changed: ChangedResult[] = [];
  const skipped: SkipResult[] = [];

  await Promise.all(
    keys.map(async (key) => {
      const license = await findLicense(key);
      if (!license) {
        skipped.push({ key, reason: 'not_found' });
        return;
      }
      const activationCount = await countActivations(key);
      if (activationCount === 0) {
        skipped.push({ key, reason: 'already_clear' });
        return;
      }
      const removedCount = await removeAllActivations(key);
      await insertAuditLog({
        licenseKey: key,
        action: 'deactivate_all',
        detail: { removedCount, bulk: true },
      });
      changed.push({ key, removedCount });
    }),
  );

  return NextResponse.json({ ok: true, changed, skipped });
}
