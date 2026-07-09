// Admin: full audit history for a single license key.
// Requires ?key=ADIA-... (mandatory). Useful for customer-support triage.
// GET ?key=ADIA-...&offset=0&limit=50&action=revoke&since=2026-01-01
//   key:    required — the license key to inspect.
//   offset: optional — default 0.
//   limit:  optional — max 200, default 50.
//   action: optional — filter to a specific action (e.g. revoke, extend).
//   since:  optional — ISO date (YYYY-MM-DD); only entries on or after this date.
//   format=csv — export all matching entries as CSV (ignores offset/limit).
// Response: { license, count: total, total, hasMore, offset, limit, entries }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, listAuditLog, countAuditLog, listAllAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';
import type { AuditEntry } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const SINCE_RE = /^\d{4}-\d{2}-\d{2}$/;

function escapeCSV(v: string | number | null | undefined): string {
  if (v == null) return '';
  const s = String(v);
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function toCSV(entries: AuditEntry[]): string {
  const header = 'id,createdAt,licenseKey,action,detail';
  const rows = entries.map(e =>
    [e.id, e.createdAt, e.licenseKey, e.action, e.detail ?? '']
      .map(escapeCSV)
      .join(','),
  );
  return [header, ...rows].join('\n');
}

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'license-timeline');
  if (denied) return denied;

  const rawKey = req.nextUrl.searchParams.get('key');
  if (!rawKey) {
    return NextResponse.json({ error: 'missing ?key=' }, { status: 400 });
  }
  const licenseKey = rawKey.trim().toUpperCase();

  const rawLimit = req.nextUrl.searchParams.get('limit');
  const rawOffset = req.nextUrl.searchParams.get('offset');
  const rawAction = req.nextUrl.searchParams.get('action');
  const rawSince = req.nextUrl.searchParams.get('since');
  const format = req.nextUrl.searchParams.get('format');

  const action = rawAction ? rawAction.trim() : undefined;
  const since = rawSince && SINCE_RE.test(rawSince.trim()) ? rawSince.trim() : undefined;
  const limit = rawLimit ? Math.min(Math.max(1, Number(rawLimit) || 50), 200) : 50;
  const offset = rawOffset ? Math.max(0, Number(rawOffset) || 0) : 0;

  const license = await findLicense(licenseKey);
  if (!license) {
    return NextResponse.json({ error: 'not found' }, { status: 404 });
  }

  if (format === 'csv') {
    const all = await listAllAuditLog(since, action, licenseKey);
    const csv = toCSV(all);
    return new Response(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="timeline-${licenseKey}.csv"`,
      },
    });
  }

  const [entries, total] = await Promise.all([
    listAuditLog({ licenseKey, limit, offset, action, since }),
    countAuditLog({ licenseKey, action, since }),
  ]);

  const hasMore = offset + entries.length < total;
  return NextResponse.json({ license, count: total, total, hasMore, offset, limit, entries });
}
