// Admin: time-to-churn distribution — for all churned licenses in the window,
// how many days elapsed from issuance to the first churn event, bucketed into
// four life-stage bands (0-7d / 8-30d / 31-90d / 91d+) with median + mean.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// Query params:
//   days=N              — look-back window in days; default 365; max 365
//   plan=monthly|yearly|lifetime  — filter to a specific plan (optional)

import { NextRequest, NextResponse } from 'next/server';
import { timeToChurn } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_PLANS = new Set(['monthly', 'yearly', 'lifetime']);
const DEFAULT_DAYS = 365;
const MAX_DAYS = 365;

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'time-to-churn');
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

  const result = await timeToChurn(days, rawPlan);
  return NextResponse.json(result);
}
