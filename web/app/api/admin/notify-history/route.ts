// Admin: list all custom emails sent to a customer (via POST /api/admin/notify).
// GET ?email=user@example.com&limit=20&offset=0
//
// Returns notify audit-log entries across ALL license keys owned by the email,
// ordered newest-first. Useful for reviewing outreach history before reaching
// out again, or auditing past communications.
//
// ?limit=N   — page size (default 20, max 100).
// ?offset=N  — skip first N records (default 0).
//
// Response: { email, count, hasMore, offset, limit, entries }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { countNotifyHistory, listNotifyHistory } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'notify-history');
  if (denied) return denied;

  const rawEmail = req.nextUrl.searchParams.get('email');
  if (!rawEmail || !rawEmail.trim()) {
    return NextResponse.json({ error: 'missing ?email=' }, { status: 400 });
  }
  const email = rawEmail.trim().toLowerCase();

  const rawLimit = parseInt(req.nextUrl.searchParams.get('limit') ?? String(DEFAULT_LIMIT), 10);
  const limit = Number.isFinite(rawLimit) && rawLimit > 0 ? Math.min(rawLimit, MAX_LIMIT) : DEFAULT_LIMIT;
  const rawOffset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0', 10);
  const offset = Number.isFinite(rawOffset) && rawOffset >= 0 ? rawOffset : 0;

  const [count, entries] = await Promise.all([
    countNotifyHistory(email),
    listNotifyHistory(email, limit, offset),
  ]);

  const hasMore = offset + entries.length < count;

  return NextResponse.json({ email, count, hasMore, offset, limit, entries });
}
