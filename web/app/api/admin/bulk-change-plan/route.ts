// Admin: change plan for multiple license keys in one batch.
// POST body: { keys: string[], plan: "monthly" | "yearly" | "lifetime" }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Compensate a cohort of users after a service outage (batch upgrade)
//   - Correct plan mismatches imported from a CSV
//   - Bulk downgrade/upgrade as part of a pricing migration
//
// Max 100 keys per request. Keys already on the target plan are silently skipped
// (returned in `skipped` array with reason="already_on_plan"). Unknown keys are
// also skipped with reason="not_found". Each successfully changed key gets its
// own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setPlan, insertAuditLog } from '@/lib/store';
import type { License } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_PLANS: License['plan'][] = ['monthly', 'yearly', 'lifetime'];
const MAX_KEYS = 100;

type ChangeResult = { key: string; previousPlan: License['plan'] };
type SkipResult = { key: string; reason: 'not_found' | 'already_on_plan' };

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'bulk-change-plan');
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

  const rawPlan = body?.plan;
  if (!rawPlan) {
    return NextResponse.json({ error: 'missing plan in body' }, { status: 400 });
  }
  if (!VALID_PLANS.includes(rawPlan)) {
    return NextResponse.json(
      { error: `invalid plan — must be one of: ${VALID_PLANS.join(', ')}` },
      { status: 400 },
    );
  }
  const plan = rawPlan as License['plan'];

  const keys = rawKeys.map((k: unknown) => String(k).trim().toUpperCase());

  const changed: ChangeResult[] = [];
  const skipped: SkipResult[] = [];

  await Promise.all(
    keys.map(async (key) => {
      const license = await findLicense(key);
      if (!license) {
        skipped.push({ key, reason: 'not_found' });
        return;
      }
      if (license.plan === plan) {
        skipped.push({ key, reason: 'already_on_plan' });
        return;
      }
      const previousPlan = license.plan;
      await setPlan(key, plan);
      await insertAuditLog({
        licenseKey: key,
        action: 'change_plan',
        detail: { previousPlan, newPlan: plan, bulk: true },
      });
      changed.push({ key, previousPlan });
    }),
  );

  return NextResponse.json({ ok: true, plan, changed, skipped });
}
