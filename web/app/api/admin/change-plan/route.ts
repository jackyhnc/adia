// Admin: change a license's plan (monthly / yearly / lifetime).
// POST body: { key: "ADIA-...", plan: "monthly" | "yearly" | "lifetime" }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Customer upgraded outside of Stripe (e.g. manual payment, compensation)
//   - Admin downgrades as part of a support resolution
//   - Correcting a plan that was set incorrectly at issue time
//
// Changes only the `plan` column. Does not touch status, expiresAt, or stripeSub —
// caller is responsible for updating those separately if needed.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setPlan, insertAuditLog } from '@/lib/store';
import type { License } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_PLANS: License['plan'][] = ['monthly', 'yearly', 'lifetime'];

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'change-plan');
  if (denied) return denied;
  const body = await req.json().catch(() => null);
  const rawKey = body?.key;
  if (!rawKey) return NextResponse.json({ error: 'missing key in body' }, { status: 400 });
  const rawPlan = body?.plan;
  if (!rawPlan) return NextResponse.json({ error: 'missing plan in body' }, { status: 400 });
  if (!VALID_PLANS.includes(rawPlan)) {
    return NextResponse.json(
      { error: `invalid plan — must be one of: ${VALID_PLANS.join(', ')}` },
      { status: 400 },
    );
  }
  const key = String(rawKey).trim().toUpperCase();
  const plan = rawPlan as License['plan'];
  const license = await findLicense(key);
  if (!license) return NextResponse.json({ error: 'unknown key' }, { status: 404 });
  if (license.plan === plan) {
    return NextResponse.json(
      { error: `license is already on the ${plan} plan`, key, plan },
      { status: 422 },
    );
  }
  const previousPlan = license.plan;
  await setPlan(key, plan);
  await insertAuditLog({ licenseKey: key, action: 'change_plan', detail: { previousPlan, newPlan: plan } });
  return NextResponse.json({ ok: true, key, previousPlan, newPlan: plan });
}
