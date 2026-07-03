// Admin: list all licenses issued to an email address.
// Auth: ADMIN_TOKEN bearer header. Never expose without it.
//
// ?limit=N     — page size (default 20, max 100). Ignored for CSV export.
// ?offset=N    — skip first N records (default 0). Ignored for CSV export.
// ?format=csv  — returns a CSV file download instead of JSON (all records, no pagination).
//   Columns: key, plan, status, machineCount, issuedAt, expiresAt, note, lastAction, lastActionAt

import { NextRequest, NextResponse } from 'next/server';
import { findLicensesByEmail, countLicensesByEmail } from '@/lib/store';

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

function csvCell(value: string | number | null | undefined): string {
  const s = value == null ? '' : String(value);
  // RFC 4180: wrap in quotes if the cell contains a comma, quote, or newline
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

const CSV_HEADER = 'key,plan,status,machineCount,issuedAt,expiresAt,note,lastAction,lastActionAt';

export async function GET(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }
  const email = req.nextUrl.searchParams.get('email');
  if (!email) return NextResponse.json({ error: 'missing ?email=' }, { status: 400 });
  const format = req.nextUrl.searchParams.get('format');

  if (format === 'csv') {
    // CSV exports all records — no pagination
    const licenses = await findLicensesByEmail(email);
    const normalized = email.trim().toLowerCase();
    const rows = licenses.map(l =>
      [
        csvCell(l.key),
        csvCell(l.plan),
        csvCell(l.status),
        csvCell(l.machineCount ?? 0),
        csvCell(l.issuedAt),
        csvCell(l.expiresAt ?? ''),
        csvCell(l.note ?? ''),
        csvCell(l.lastAction ?? ''),
        csvCell(l.lastActionAt ?? ''),
      ].join(','),
    );
    const csv = [CSV_HEADER, ...rows].join('\r\n');
    const filename = `licenses-${normalized}-${new Date().toISOString().slice(0, 10)}.csv`;
    return new NextResponse(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="${filename}"`,
      },
    });
  }

  const rawLimit = parseInt(req.nextUrl.searchParams.get('limit') ?? String(DEFAULT_LIMIT), 10);
  const limit = Number.isFinite(rawLimit) && rawLimit > 0 ? Math.min(rawLimit, MAX_LIMIT) : DEFAULT_LIMIT;
  const rawOffset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0', 10);
  const offset = Number.isFinite(rawOffset) && rawOffset >= 0 ? rawOffset : 0;

  const [total, licenses] = await Promise.all([
    countLicensesByEmail(email),
    findLicensesByEmail(email, limit, offset),
  ]);

  return NextResponse.json({
    email: email.trim().toLowerCase(),
    count: total,
    licenses,
    hasMore: offset + licenses.length < total,
    offset,
  });
}
