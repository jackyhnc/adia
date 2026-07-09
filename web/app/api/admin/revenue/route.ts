// Admin: MRR / ARR / lifetime revenue metrics.
// Auth: ADMIN_TOKEN bearer header.

import { NextRequest, NextResponse } from 'next/server';
import { revenueMetrics } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'revenue');
  if (denied) return denied;
  const metrics = await revenueMetrics();
  return NextResponse.json(metrics);
}
