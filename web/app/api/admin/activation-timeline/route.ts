// Admin: daily activation counts over the past N days.
// Returns an array of { date: "YYYY-MM-DD", count: N } buckets, oldest first.
// Days with no activations are included with count=0.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// Query params:
//   days=N       — look-back window in days; default 30; max 365
//   plan=monthly|yearly|lifetime  — filter to a specific plan (optional)

import { NextRequest, NextResponse } from 'next/server';
import { activationTimeline } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_PLANS = new Set(['monthly', 'yearly', 'lifetime']);
const DEFAULT_DAYS = 30;
const MAX_DAYS = 365;

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'activation-timeline');
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

  const buckets = await activationTimeline(days, rawPlan);
  const total = buckets.reduce((s, b) => s + b.count, 0);

  const response: Record<string, unknown> = { buckets, total, days };
  if (rawPlan) response.plan = rawPlan;
  return NextResponse.json(response);
}
