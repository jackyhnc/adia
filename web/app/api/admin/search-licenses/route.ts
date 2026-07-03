// Admin: full-text search across license key, email, and note.
// GET ?q=...&limit=20&offset=0          → { count, total, hasMore, offset, limit, results: License[] }
// GET ?q=...&format=csv                 → CSV download of all matching licenses
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { searchLicenses, countSearchLicenses, searchLicensesAll } from '@/lib/store';

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
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

const CSV_HEADER = 'key,email,plan,status,machineCount,issuedAt,expiresAt,note';

export async function GET(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }
  const q = req.nextUrl.searchParams.get('q');
  if (!q || !q.trim()) {
    return NextResponse.json({ error: 'missing ?q= search query' }, { status: 400 });
  }
  const format = req.nextUrl.searchParams.get('format');

  if (format === 'csv') {
    const licenses = await searchLicensesAll(q.trim());
    const rows = licenses.map(l =>
      [
        csvCell(l.key),
        csvCell(l.email),
        csvCell(l.plan),
        csvCell(l.status),
        csvCell(l.machineCount ?? 0),
        csvCell(l.issuedAt),
        csvCell(l.expiresAt ?? ''),
        csvCell(l.note ?? ''),
      ].join(','),
    );
    const csv = [CSV_HEADER, ...rows].join('\r\n');
    const safeQ = q.trim().replace(/[^a-zA-Z0-9@._-]/g, '_').slice(0, 40);
    const date = new Date().toISOString().slice(0, 10);
    const filename = `search-${safeQ}-${date}.csv`;
    return new NextResponse(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="${filename}"`,
      },
    });
  }

  const rawLimit = req.nextUrl.searchParams.get('limit');
  const limit = rawLimit ? Math.min(Math.max(1, Number(rawLimit) || 20), 100) : 20;
  const rawOffset = req.nextUrl.searchParams.get('offset');
  const offset = rawOffset ? Math.max(0, Number(rawOffset) || 0) : 0;
  const [results, total] = await Promise.all([
    searchLicenses(q.trim(), limit, offset),
    countSearchLicenses(q.trim()),
  ]);
  return NextResponse.json({
    count: results.length,
    total,
    hasMore: offset + results.length < total,
    offset,
    limit,
    results,
  });
}
