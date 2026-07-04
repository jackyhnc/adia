// Admin: list admin audit log entries.
// GET ?key=ADIA-...&limit=100&offset=0&action=revoke
//   key: optional — filter by license key.
//   action: optional — filter by action name (e.g. revoke, issue, extend).
//   limit: optional — max 500, default 100.
//   offset: optional — default 0. Enables pagination.
//   format=csv — download as CSV (no pagination; exports current page).
// Response: { count: total, total, hasMore, offset, limit, entries }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { listAuditLog, countAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'audit-log');
  if (denied) return denied;

  const rawKey = req.nextUrl.searchParams.get('key');
  const rawLimit = req.nextUrl.searchParams.get('limit');
  const rawOffset = req.nextUrl.searchParams.get('offset');
  const rawAction = req.nextUrl.searchParams.get('action');
  const format = req.nextUrl.searchParams.get('format');

  const licenseKey = rawKey ? rawKey.trim().toUpperCase() : undefined;
  const action = rawAction ? rawAction.trim() : undefined;
  const limit = rawLimit ? Math.min(Math.max(1, Number(rawLimit) || 100), 500) : 100;
  const offset = rawOffset ? Math.max(0, Number(rawOffset) || 0) : 0;

  const [entries, total] = await Promise.all([
    listAuditLog({ licenseKey, limit, offset, action }),
    countAuditLog({ licenseKey, action }),
  ]);

  if (format === 'csv') {
    const header = 'id,createdAt,licenseKey,action,detail\n';
    const rows = entries.map((e) => {
      const detail = (e.detail ?? '').replace(/"/g, '""');
      const key = (e.licenseKey ?? '').replace(/"/g, '""');
      return `${e.id},"${e.createdAt}","${key}","${e.action}","${detail}"`;
    });
    const csv = header + rows.join('\n');
    return new Response(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': 'attachment; filename="audit-log.csv"',
      },
    });
  }

  const hasMore = offset + entries.length < total;
  return NextResponse.json({ count: total, total, hasMore, offset, limit, entries });
}
