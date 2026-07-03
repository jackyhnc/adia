// Admin: full-text search across license key, email, and note.
// GET ?q=...&limit=20&offset=0 → { count, total, hasMore, offset, limit, results: License[] }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { searchLicenses, countSearchLicenses } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

export async function GET(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }
  const q = req.nextUrl.searchParams.get('q');
  if (!q || !q.trim()) {
    return NextResponse.json({ error: 'missing ?q= search query' }, { status: 400 });
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
