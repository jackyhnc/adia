// Admin: export all audit log entries as CSV or JSON.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// Query params:
//   format=csv (default) | json
//   since=<ISO-date>        e.g. 2025-01-01
//   action=<action-name>    e.g. issue, revoke, set_status
//   licenseKey=<ADIA-...>   restrict to a single license key

import { NextRequest, NextResponse } from 'next/server';
import { listAllAuditLog } from '@/lib/store';
import type { AuditEntry } from '@/lib/store';
import { adminGuard } from '@/lib/admin';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function escapeCSV(v: string | number | null | undefined): string {
  if (v == null) return '';
  const s = String(v);
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function toCSV(entries: AuditEntry[], date: string): string {
  const header = 'id,createdAt,licenseKey,action,detail';
  const rows = entries.map(e =>
    [e.id, e.createdAt, e.licenseKey, e.action, e.detail]
      .map(escapeCSV)
      .join(','),
  );
  return [header, ...rows].join('\n');
}

export async function GET(req: NextRequest) {
  // Tighter export rate limit (10 req/60 s) on a separate bucket so bulk
  // CSV downloads can't starve the shared adminGuard bucket.
  const rl = rateLimit(`export-audit-log:${clientIp(req)}`, 10, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }

  const denied = adminGuard(req, 'audit-log-export');
  if (denied) return denied;

  const sp = req.nextUrl.searchParams;
  const format = sp.get('format') ?? 'csv';
  if (format !== 'csv' && format !== 'json') {
    return NextResponse.json({ error: 'invalid format; use csv or json' }, { status: 400 });
  }

  const since = sp.get('since') ?? undefined;
  if (since && isNaN(Date.parse(since))) {
    return NextResponse.json({ error: 'invalid since; must be a parseable date string' }, { status: 400 });
  }

  const action = sp.get('action') ?? undefined;
  const licenseKey = sp.get('licenseKey') ?? undefined;

  const entries = await listAllAuditLog(since, action, licenseKey);

  if (format === 'json') {
    return NextResponse.json({ entries, count: entries.length });
  }

  const date = new Date().toISOString().slice(0, 10);
  const csv = toCSV(entries, date);
  const filename = `adia-audit-log-${date}.csv`;
  return new NextResponse(csv, {
    status: 200,
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Cache-Control': 'no-store',
    },
  });
}
