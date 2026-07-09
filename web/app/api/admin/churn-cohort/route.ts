// Admin: per-cohort churn breakdown — for each issuance-date cohort in the
// selected window, shows how many licenses churned (ever) and how quickly
// (within 30/60/90 days of issuance). Complements cohort-retention.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// Query params:
//   days=N              — look-back window in days; default 90; max 365
//   plan=monthly|yearly|lifetime  — filter to a specific plan (optional)

import { NextRequest, NextResponse } from 'next/server';
import { churnCohort } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_PLANS = new Set(['monthly', 'yearly', 'lifetime']);
const DEFAULT_DAYS = 90;
const MAX_DAYS = 365;

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'churn-cohort');
  if (denied) return denied;

  const sp = req.nextUrl.searchParams;

  const rawDays = sp.get('days') ?? String(DEFAULT_DAYS);
  const days = Number(rawDays);
  if (!Number.isInteger(days) || days < 1 || days > MAX_DAYS) {
    return NextResponse.json(
      { error: `invalid days; must be an integer between 1 and ${MAX_DAYS}` },
      { status: 400 },
    );
  }

  const rawPlan = sp.get('plan') ?? undefined;
  if (rawPlan !== undefined && !VALID_PLANS.has(rawPlan)) {
    return NextResponse.json(
      { error: `invalid plan; must be one of: ${[...VALID_PLANS].join(', ')}` },
      { status: 400 },
    );
  }

  const result = await churnCohort(days, rawPlan);
  return NextResponse.json(result);
}
