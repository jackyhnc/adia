// Admin: list all licenses issued to an email address.
// Auth: ADMIN_TOKEN bearer header. Never expose without it.
//
// ?format=csv  — returns a CSV file download instead of JSON.
//   Columns: key, plan, status, machineCount, issuedAt, expiresAt, note, lastAction, lastActionAt

import { NextRequest, NextResponse } from 'next/server';
import { findLicensesByEmail } from '@/lib/store';

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
  const licenses = await findLicensesByEmail(email);

  if (format === 'csv') {
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

  return NextResponse.json({ email: email.trim().toLowerCase(), count: licenses.length, licenses });
}
