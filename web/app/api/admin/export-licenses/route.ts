// Admin: export all licenses as CSV or JSON.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// Query params:
//   format=csv (default) | json
//   status=active|canceled|expired|past_due
//   plan=monthly|yearly|lifetime
//   since=<ISO-date>   e.g. 2025-01-01

import { NextRequest, NextResponse } from 'next/server';
import { listAllLicenses } from '@/lib/store';
import type { License } from '@/lib/store';
import { adminGuard } from '@/lib/admin';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_STATUSES = new Set(['active', 'canceled', 'expired', 'past_due']);
const VALID_PLANS = new Set(['monthly', 'yearly', 'lifetime']);

function toCSV(licenses: License[]): string {
  const header = 'key,email,plan,status,issuedAt,expiresAt,machineCount,note';
  const escape = (v: string | null | undefined): string => {
    if (v == null) return '';
    const s = String(v);
    if (s.includes(',') || s.includes('"') || s.includes('\n')) {
      return `"${s.replace(/"/g, '""')}"`;
    }
    return s;
  };
  const rows = licenses.map(l =>
    [l.key, l.email, l.plan, l.status, l.issuedAt, l.expiresAt, l.machineCount, l.note]
      .map(v => escape(v as any))
      .join(','),
  );
  return [header, ...rows].join('\n');
}

export async function GET(req: NextRequest) {
  // Tighter export rate limit (10 req/60 s) on a separate bucket so bulk
  // CSV downloads can't starve the shared adminGuard bucket.
  const rl = rateLimit(`export-licenses:${clientIp(req)}`, 10, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }

  const denied = adminGuard(req, 'export-licenses');
  if (denied) return denied;

  const sp = req.nextUrl.searchParams;
  const format = sp.get('format') ?? 'csv';
  if (format !== 'csv' && format !== 'json') {
    return NextResponse.json({ error: 'invalid format; use csv or json' }, { status: 400 });
  }

  const status = sp.get('status') ?? undefined;
  if (status && !VALID_STATUSES.has(status)) {
    return NextResponse.json({ error: `invalid status; must be one of ${[...VALID_STATUSES].join(', ')}` }, { status: 400 });
  }

  const plan = sp.get('plan') ?? undefined;
  if (plan && !VALID_PLANS.has(plan)) {
    return NextResponse.json({ error: `invalid plan; must be one of ${[...VALID_PLANS].join(', ')}` }, { status: 400 });
  }

  const since = sp.get('since') ?? undefined;
  if (since && isNaN(Date.parse(since))) {
    return NextResponse.json({ error: 'invalid since; must be a parseable date string' }, { status: 400 });
  }

  const licenses = await listAllLicenses(since, status, plan);

  if (format === 'json') {
    return NextResponse.json({ licenses, count: licenses.length });
  }

  const csv = toCSV(licenses);
  const filename = `adia-licenses-${new Date().toISOString().slice(0, 10)}.csv`;
  return new NextResponse(csv, {
    status: 200,
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Cache-Control': 'no-store',
    },
  });
}
