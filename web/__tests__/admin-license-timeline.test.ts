// Tests for GET /api/admin/license-timeline

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, insertAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

vi.mock('@/lib/email', () => ({
  sendLicenseEmail: vi.fn().mockResolvedValue(undefined),
  sendPaymentFailedEmail: vi.fn().mockResolvedValue(undefined),
}));

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-timeline-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

function authHeader(token = 'test-admin-token') {
  return { Authorization: `Bearer ${token}` };
}

async function callTimeline(params: Record<string, string> = {}, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/license-timeline/route');
  const qs = new URLSearchParams(params).toString();
  const req = new NextRequest(
    `http://localhost/api/admin/license-timeline${qs ? `?${qs}` : ''}`,
    { method: 'GET', headers: authHeader(token) },
  );
  return GET(req);
}

// ─── Auth ───────────────────────────────────────────────────────────────────

describe('auth', () => {
  it('401 when no token', async () => {
    insertLicense({ key: 'ADIA-AUTH1', email: 'a@a.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/license-timeline/route');
    const req = new NextRequest('http://localhost/api/admin/license-timeline?key=ADIA-AUTH1', {
      method: 'GET',
    });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('401 when wrong token', async () => {
    insertLicense({ key: 'ADIA-AUTH2', email: 'a@a.com', plan: 'monthly', expiresAt: null });
    const res = await callTimeline({ key: 'ADIA-AUTH2' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('200 with ?token= query param', async () => {
    insertLicense({ key: 'ADIA-AUTH3', email: 'a@a.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/license-timeline/route');
    const req = new NextRequest(
      'http://localhost/api/admin/license-timeline?key=ADIA-AUTH3&token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ─────────────────────────────────────────────────────────────

describe('validation', () => {
  it('400 when ?key= is missing', async () => {
    const res = await callTimeline({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/key/i);
  });

  it('404 when key does not exist', async () => {
    const res = await callTimeline({ key: 'ADIA-NOTFOUND' });
    expect(res.status).toBe(404);
  });
});

// ─── Core behavior ──────────────────────────────────────────────────────────

describe('core behavior', () => {
  it('returns license object alongside empty entries when no audit log', async () => {
    insertLicense({ key: 'ADIA-TL01', email: 'tl01@example.com', plan: 'monthly', expiresAt: null });
    const res = await callTimeline({ key: 'ADIA-TL01' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.license.key).toBe('ADIA-TL01');
    expect(body.license.email).toBe('tl01@example.com');
    expect(body.entries).toEqual([]);
    expect(body.total).toBe(0);
    expect(body.hasMore).toBe(false);
  });

  it('returns audit entries for the specified license key only', async () => {
    insertLicense({ key: 'ADIA-TL02', email: 'tl02@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-TL03', email: 'tl03@example.com', plan: 'yearly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-TL02', action: 'revoke', detail: 'test' });
    insertAuditLog({ licenseKey: 'ADIA-TL03', action: 'extend', detail: 'other' });
    insertAuditLog({ licenseKey: 'ADIA-TL02', action: 'issue', detail: null });

    const res = await callTimeline({ key: 'ADIA-TL02' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(2);
    expect(body.entries.every((e: { licenseKey: string }) => e.licenseKey === 'ADIA-TL02')).toBe(true);
  });

  it('key is normalized to uppercase', async () => {
    insertLicense({ key: 'ADIA-TL04', email: 'tl04@example.com', plan: 'monthly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-TL04', action: 'revoke', detail: null });
    const res = await callTimeline({ key: 'adia-tl04' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(1);
  });

  it('response includes count, total, hasMore, offset, limit fields', async () => {
    insertLicense({ key: 'ADIA-TL05', email: 'tl05@example.com', plan: 'monthly', expiresAt: null });
    const res = await callTimeline({ key: 'ADIA-TL05' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(typeof body.count).toBe('number');
    expect(typeof body.total).toBe('number');
    expect(typeof body.hasMore).toBe('boolean');
    expect(typeof body.offset).toBe('number');
    expect(typeof body.limit).toBe('number');
  });
});

// ─── Pagination ──────────────────────────────────────────────────────────────

describe('pagination', () => {
  it('respects limit param', async () => {
    insertLicense({ key: 'ADIA-PG01', email: 'pg01@example.com', plan: 'monthly', expiresAt: null });
    for (let i = 0; i < 5; i++) {
      insertAuditLog({ licenseKey: 'ADIA-PG01', action: 'note', detail: `note ${i}` });
    }
    const res = await callTimeline({ key: 'ADIA-PG01', limit: '2' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.entries.length).toBe(2);
    expect(body.total).toBe(5);
    expect(body.hasMore).toBe(true);
  });

  it('respects offset param', async () => {
    insertLicense({ key: 'ADIA-PG02', email: 'pg02@example.com', plan: 'monthly', expiresAt: null });
    for (let i = 0; i < 3; i++) {
      insertAuditLog({ licenseKey: 'ADIA-PG02', action: 'note', detail: `note ${i}` });
    }
    const res = await callTimeline({ key: 'ADIA-PG02', offset: '2' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.entries.length).toBe(1);
    expect(body.hasMore).toBe(false);
    expect(body.offset).toBe(2);
  });

  it('hasMore is false when all entries fit on one page', async () => {
    insertLicense({ key: 'ADIA-PG03', email: 'pg03@example.com', plan: 'monthly', expiresAt: null });
    for (let i = 0; i < 3; i++) {
      insertAuditLog({ licenseKey: 'ADIA-PG03', action: 'note', detail: `n${i}` });
    }
    const res = await callTimeline({ key: 'ADIA-PG03', limit: '10' });
    const body = await res.json();
    expect(body.hasMore).toBe(false);
  });

  it('limit is capped at 200', async () => {
    insertLicense({ key: 'ADIA-PG04', email: 'pg04@example.com', plan: 'monthly', expiresAt: null });
    const res = await callTimeline({ key: 'ADIA-PG04', limit: '9999' });
    const body = await res.json();
    expect(body.limit).toBe(200);
  });
});

// ─── Action filter ───────────────────────────────────────────────────────────

describe('action filter', () => {
  it('filters entries by action', async () => {
    insertLicense({ key: 'ADIA-AF01', email: 'af01@example.com', plan: 'monthly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-AF01', action: 'revoke', detail: null });
    insertAuditLog({ licenseKey: 'ADIA-AF01', action: 'extend', detail: null });
    insertAuditLog({ licenseKey: 'ADIA-AF01', action: 'revoke', detail: null });

    const res = await callTimeline({ key: 'ADIA-AF01', action: 'revoke' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(2);
    expect(body.entries.every((e: { action: string }) => e.action === 'revoke')).toBe(true);
  });

  it('returns zero entries for unmatched action', async () => {
    insertLicense({ key: 'ADIA-AF02', email: 'af02@example.com', plan: 'monthly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-AF02', action: 'revoke', detail: null });

    const res = await callTimeline({ key: 'ADIA-AF02', action: 'extend' });
    const body = await res.json();
    expect(body.total).toBe(0);
    expect(body.entries).toEqual([]);
  });
});

// ─── Since filter ────────────────────────────────────────────────────────────

describe('since filter', () => {
  it('ignores invalid since value', async () => {
    insertLicense({ key: 'ADIA-SF01', email: 'sf01@example.com', plan: 'monthly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-SF01', action: 'revoke', detail: null });
    // 'not-a-date' is not YYYY-MM-DD — should be ignored; all entries returned
    const res = await callTimeline({ key: 'ADIA-SF01', since: 'not-a-date' });
    const body = await res.json();
    expect(body.total).toBe(1);
  });
});

// ─── CSV export ──────────────────────────────────────────────────────────────

describe('csv export', () => {
  it('returns CSV content-type for ?format=csv', async () => {
    insertLicense({ key: 'ADIA-CSV1', email: 'csv1@example.com', plan: 'monthly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-CSV1', action: 'revoke', detail: 'test' });
    const res = await callTimeline({ key: 'ADIA-CSV1', format: 'csv' });
    expect(res.status).toBe(200);
    expect(res.headers.get('Content-Type')).toMatch(/text\/csv/i);
  });

  it('CSV export filename includes the license key', async () => {
    insertLicense({ key: 'ADIA-CSV2', email: 'csv2@example.com', plan: 'monthly', expiresAt: null });
    const res = await callTimeline({ key: 'ADIA-CSV2', format: 'csv' });
    const disposition = res.headers.get('Content-Disposition') ?? '';
    expect(disposition).toContain('ADIA-CSV2');
  });

  it('CSV has header row and one data row per entry', async () => {
    insertLicense({ key: 'ADIA-CSV3', email: 'csv3@example.com', plan: 'monthly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-CSV3', action: 'revoke', detail: 'reason' });
    insertAuditLog({ licenseKey: 'ADIA-CSV3', action: 'note', detail: 'memo' });
    const res = await callTimeline({ key: 'ADIA-CSV3', format: 'csv' });
    const text = await res.text();
    const lines = text.trim().split('\n');
    expect(lines[0]).toContain('id');
    expect(lines[0]).toContain('action');
    expect(lines.length).toBe(3); // header + 2 entries
  });

  it('404 for CSV export when key is unknown', async () => {
    const res = await callTimeline({ key: 'ADIA-NOSUCH', format: 'csv' });
    expect(res.status).toBe(404);
  });

  it('rate-limit fires before CSV format parsing on exhausted bucket', async () => {
    resetRateLimit();
    insertLicense({ key: 'ADIA-CSVRL', email: 'rl@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/license-timeline/route');
    // Exhaust the rate-limit bucket (20 req / 60s)
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest(
        `http://localhost/api/admin/license-timeline?key=ADIA-CSVRL`,
        { method: 'GET', headers: authHeader() },
      );
      await GET(req);
    }
    // The 21st request — ?format=csv — should 429, not 400 or 200
    const req = new NextRequest(
      'http://localhost/api/admin/license-timeline?key=ADIA-CSVRL&format=csv',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(429);
  });
});
