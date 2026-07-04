// Admin: list active licenses expiring within the next N days.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// Query params:
//   days=N        — look-ahead window (default 30, max 365)
//   plan=monthly|yearly — filter to a specific plan (lifetime licenses are never returned)
//   format=csv    — download as CSV instead of JSON

import { NextRequest, NextResponse } from 'next/server';
import { listExpiringLicenses } from '@/lib/store';
import type { License } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const DEFAULT_DAYS = 30;
const MAX_DAYS = 365;
const VALID_PLANS = new Set(['monthly', 'yearly']);

function escapeCSV(v: string | number | null | undefined): string {
  if (v == null) return '';
  const s = String(v);
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function toCSV(licenses: License[]): string {
  const header = 'key,email,plan,status,expiresAt,machineCount,note';
  const rows = licenses.map(l =>
    [l.key, l.email, l.plan, l.status, l.expiresAt, l.machineCount ?? 0, l.note ?? '']
      .map(escapeCSV)
      .join(','),
  );
  return [header, ...rows].join('\n');
}

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'expiring-soon');
  if (denied) return denied;

  const sp = req.nextUrl.searchParams;

  const rawDays = parseInt(sp.get('days') ?? String(DEFAULT_DAYS), 10);
  if (!Number.isFinite(rawDays) || rawDays < 1) {
    return NextResponse.json({ error: 'invalid days; must be a positive integer' }, { status: 400 });
  }
  const days = Math.min(rawDays, MAX_DAYS);

  const rawPlan = sp.get('plan') ?? undefined;
  if (rawPlan !== undefined && !VALID_PLANS.has(rawPlan)) {
    return NextResponse.json(
      { error: `invalid plan; must be one of: ${[...VALID_PLANS].join(', ')}` },
      { status: 400 },
    );
  }

  const format = sp.get('format') ?? 'json';
  if (format !== 'json' && format !== 'csv') {
    return NextResponse.json({ error: 'invalid format; use json or csv' }, { status: 400 });
  }

  const licenses = await listExpiringLicenses(days, rawPlan);

  if (format === 'csv') {
    const csv = toCSV(licenses);
    const date = new Date().toISOString().slice(0, 10);
    const filename = `adia-expiring-${days}d-${date}.csv`;
    return new NextResponse(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Cache-Control': 'no-store',
      },
    });
  }

  return NextResponse.json({ licenses, count: licenses.length, days });
}
