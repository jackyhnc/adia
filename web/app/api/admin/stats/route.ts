// Admin: aggregate license statistics.
// Auth: ADMIN_TOKEN bearer header. Never expose without it.

import { NextRequest, NextResponse } from 'next/server';
import { getStats } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'stats');
  if (denied) return denied;
  const stats = await getStats();
  return NextResponse.json(stats);
}
