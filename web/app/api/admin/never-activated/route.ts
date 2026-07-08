// Admin: list licenses that have never been activated (machineCount = 0).
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// Query params:
//   plan=monthly|yearly|lifetime  — filter to a specific plan (optional)
//   since=YYYY-MM-DD              — only licenses issued on or after this date (optional)
//   status=active|canceled|expired|past_due — filter by status (optional; default: all)
//   format=csv                    — download as CSV instead of JSON

import { NextRequest, NextResponse } from 'next/server';
import { listNeverActivatedLicenses } from '@/lib/store';
import type { License } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_PLANS = new Set(['monthly', 'yearly', 'lifetime']);
const VALID_STATUSES = new Set(['active', 'canceled', 'expired', 'past_due']);

function escapeCSV(v: string | number | null | undefined): string {
  if (v == null) return '';
  const s = String(v);
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function toCSV(licenses: License[]): string {
  const header = 'key,email,plan,status,issuedAt,machineCount,note';
  const rows = licenses.map(l =>
    [l.key, l.email, l.plan, l.status, l.issuedAt, l.machineCount ?? 0, l.note ?? '']
      .map(escapeCSV)
      .join(','),
  );
  return [header, ...rows].join('\n');
}

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'never-activated');
  if (denied) return denied;

  const sp = req.nextUrl.searchParams;

  const rawPlan = sp.get('plan') ?? undefined;
  if (rawPlan !== undefined && !VALID_PLANS.has(rawPlan)) {
    return NextResponse.json(
      { error: `invalid plan; must be one of: ${[...VALID_PLANS].join(', ')}` },
      { status: 400 },
    );
  }

  const rawStatus = sp.get('status') ?? undefined;
  if (rawStatus !== undefined && !VALID_STATUSES.has(rawStatus)) {
    return NextResponse.json(
      { error: `invalid status; must be one of: ${[...VALID_STATUSES].join(', ')}` },
      { status: 400 },
    );
  }

  const since = sp.get('since') ?? undefined;

  const format = sp.get('format') ?? 'json';
  if (format !== 'json' && format !== 'csv') {
    return NextResponse.json({ error: 'invalid format; use json or csv' }, { status: 400 });
  }

  const licenses = await listNeverActivatedLicenses(rawPlan, since, rawStatus);

  if (format === 'csv') {
    const csv = toCSV(licenses);
    const date = new Date().toISOString().slice(0, 10);
    const filename = `adia-never-activated-${date}.csv`;
    return new NextResponse(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Cache-Control': 'no-store',
      },
    });
  }

  return NextResponse.json({ licenses, count: licenses.length });
}
