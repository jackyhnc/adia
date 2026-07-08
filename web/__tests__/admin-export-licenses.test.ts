// Tests for GET /api/admin/export-licenses

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense } from '@/lib/db';
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
    `adia-export-licenses-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callExport(params: Record<string, string> = {}, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/export-licenses/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(
    `http://localhost/api/admin/export-licenses?${sp.toString()}`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  return GET(req);
}

// ─── Auth ────────────────────────────────────────────────────────────────────

describe('GET /api/admin/export-licenses — auth', () => {
  it('returns 401 with no token', async () => {
    const { GET } = await import('@/app/api/admin/export-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/export-licenses');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callExport({}, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/export-licenses/route');
    const req = new NextRequest(
      'http://localhost/api/admin/export-licenses?token=test-admin-token&format=json',
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ──────────────────────────────────────────────────────────────

describe('GET /api/admin/export-licenses — validation', () => {
  it('returns 400 for invalid format', async () => {
    const res = await callExport({ format: 'xml' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/format/);
  });

  it('returns 400 for invalid status', async () => {
    const res = await callExport({ status: 'suspended' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/status/);
  });

  it('returns 400 for invalid plan', async () => {
    const res = await callExport({ plan: 'enterprise' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/plan/);
  });

  it('returns 400 for invalid since date', async () => {
    const res = await callExport({ since: 'not-a-date' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/since/);
  });
});

// ─── Empty table ─────────────────────────────────────────────────────────────

describe('GET /api/admin/export-licenses — empty table', () => {
  it('returns CSV with header row only when table is empty', async () => {
    const res = await callExport({ format: 'csv' });
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
    const text = await res.text();
    expect(text.trim()).toBe('key,email,plan,status,issuedAt,expiresAt,machineCount,note');
  });

  it('returns JSON with empty licenses array when table is empty', async () => {
    const res = await callExport({ format: 'json' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.licenses).toEqual([]);
    expect(body.count).toBe(0);
  });
});

// ─── Data export ─────────────────────────────────────────────────────────────

describe('GET /api/admin/export-licenses — with data', () => {
  beforeEach(() => {
    insertLicense({ key: 'ADIA-EXPL-MNT-AAAA', email: 'monthly@test.com', plan: 'monthly', expiresAt: '2026-12-31' });
    insertLicense({ key: 'ADIA-EXPL-YRL-BBBB', email: 'yearly@test.com', plan: 'yearly', expiresAt: '2027-06-30' });
    insertLicense({ key: 'ADIA-EXPL-LTM-CCCC', email: 'lifetime@test.com', plan: 'lifetime', expiresAt: null });
  });

  it('CSV export contains header + one row per license', async () => {
    const res = await callExport({ format: 'csv' });
    expect(res.status).toBe(200);
    const text = await res.text();
    const lines = text.trim().split('\n');
    expect(lines.length).toBe(4); // header + 3 data rows
  });

  it('CSV export has Content-Disposition with dated filename', async () => {
    const res = await callExport({ format: 'csv' });
    const cd = res.headers.get('content-disposition') ?? '';
    expect(cd).toMatch(/attachment/);
    expect(cd).toMatch(/adia-licenses-\d{4}-\d{2}-\d{2}\.csv/);
  });

  it('CSV export has Cache-Control: no-store', async () => {
    const res = await callExport({ format: 'csv' });
    expect(res.headers.get('cache-control')).toBe('no-store');
  });

  it('JSON export returns all licenses with count', async () => {
    const res = await callExport({ format: 'json' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(3);
    expect(body.licenses).toHaveLength(3);
    expect(body.licenses[0]).toHaveProperty('key');
    expect(body.licenses[0]).toHaveProperty('email');
    expect(body.licenses[0]).toHaveProperty('plan');
    expect(body.licenses[0]).toHaveProperty('status');
  });

  it('status filter restricts to matching licenses only', async () => {
    const res = await callExport({ format: 'json', status: 'active' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(3); // all three are active by default
    body.licenses.forEach((l: any) => expect(l.status).toBe('active'));
  });

  it('plan filter restricts to matching licenses only', async () => {
    const res = await callExport({ format: 'json', plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].plan).toBe('monthly');
  });

  it('plan filter for lifetime returns only lifetime licenses', async () => {
    const res = await callExport({ format: 'json', plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-EXPL-LTM-CCCC');
  });

  it('since filter with future date returns no licenses', async () => {
    const res = await callExport({ format: 'json', since: '2099-01-01' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
  });

  it('since filter with past date returns all licenses', async () => {
    const res = await callExport({ format: 'json', since: '2000-01-01' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(3);
  });

  it('combined plan + status filter narrows results correctly', async () => {
    const res = await callExport({ format: 'json', plan: 'yearly', status: 'active' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].plan).toBe('yearly');
    expect(body.licenses[0].status).toBe('active');
  });

  it('CSV email field appears in the data row', async () => {
    const res = await callExport({ format: 'csv', plan: 'lifetime' });
    expect(res.status).toBe(200);
    const text = await res.text();
    expect(text).toContain('lifetime@test.com');
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/export-licenses — rate limit', () => {
  it('returns 429 after 10 requests from the same IP', async () => {
    for (let i = 0; i < 10; i++) {
      const res = await callExport({ format: 'json' });
      expect(res.status).toBe(200);
    }
    const overLimit = await callExport({ format: 'json' });
    expect(overLimit.status).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    for (let i = 0; i < 10; i++) {
      await callExport({ format: 'json' });
    }
    const res = await callExport({ format: 'json' });
    expect(res.status).toBe(429);
    expect(res.headers.get('retry-after')).toBeTruthy();
  });

  it('rate limit bucket is separate from adminGuard bucket', async () => {
    // Exhaust the export-specific bucket (10 req/60s).
    for (let i = 0; i < 10; i++) {
      await callExport({ format: 'json' });
    }
    // The 11th call is blocked by the export bucket, not the adminGuard bucket.
    const res = await callExport({ format: 'json' });
    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body.error).toMatch(/too many requests/);
  });
});
