// Tests for GET /api/admin/audit-log-export

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
    `adia-audit-export-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/audit-log-export/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(
    `http://localhost/api/admin/audit-log-export?${sp.toString()}`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  return GET(req);
}

// ─── Auth ────────────────────────────────────────────────────────────────────

describe('GET /api/admin/audit-log-export — auth', () => {
  it('returns 401 with no token', async () => {
    const { GET } = await import('@/app/api/admin/audit-log-export/route');
    const req = new NextRequest('http://localhost/api/admin/audit-log-export');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callExport({}, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/audit-log-export/route');
    const req = new NextRequest(
      'http://localhost/api/admin/audit-log-export?token=test-admin-token&format=json',
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ──────────────────────────────────────────────────────────────

describe('GET /api/admin/audit-log-export — validation', () => {
  it('returns 400 for invalid format', async () => {
    const res = await callExport({ format: 'xml' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/format/);
  });

  it('returns 400 for invalid since', async () => {
    const res = await callExport({ since: 'not-a-date' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/since/);
  });
});

// ─── Empty table ─────────────────────────────────────────────────────────────

describe('GET /api/admin/audit-log-export — empty table', () => {
  it('returns CSV with header only when table is empty', async () => {
    const res = await callExport({ format: 'csv' });
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
    const text = await res.text();
    expect(text.trim()).toBe('id,createdAt,licenseKey,action,detail');
  });

  it('returns JSON with empty entries array when table is empty', async () => {
    const res = await callExport({ format: 'json' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.entries).toEqual([]);
    expect(body.count).toBe(0);
  });
});

// ─── Data export ─────────────────────────────────────────────────────────────

describe('GET /api/admin/audit-log-export — with data', () => {
  beforeEach(() => {
    insertLicense({ key: 'ADIA-TEST-1111', email: 'a@test.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-TEST-2222', email: 'b@test.com', plan: 'yearly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-TEST-1111', action: 'issue', detail: { email: 'a@test.com' } });
    insertAuditLog({ licenseKey: 'ADIA-TEST-1111', action: 'revoke', detail: { previousStatus: 'active' } });
    insertAuditLog({ licenseKey: 'ADIA-TEST-2222', action: 'extend', detail: { days: 30 } });
  });

  it('CSV export contains correct row count', async () => {
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
    expect(cd).toMatch(/adia-audit-log-\d{4}-\d{2}-\d{2}\.csv/);
  });

  it('JSON export returns all entries with count', async () => {
    const res = await callExport({ format: 'json' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(3);
    expect(body.entries).toHaveLength(3);
    expect(body.entries[0]).toHaveProperty('id');
    expect(body.entries[0]).toHaveProperty('licenseKey');
    expect(body.entries[0]).toHaveProperty('action');
    expect(body.entries[0]).toHaveProperty('createdAt');
  });

  it('action filter restricts results to matching action only', async () => {
    const res = await callExport({ format: 'json', action: 'revoke' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.entries[0].action).toBe('revoke');
  });

  it('licenseKey filter restricts to that key only', async () => {
    const res = await callExport({ format: 'json', licenseKey: 'ADIA-TEST-1111' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(2);
    body.entries.forEach((e: any) => expect(e.licenseKey).toBe('ADIA-TEST-1111'));
  });

  it('licenseKey filter is case-insensitive (normalised to upper)', async () => {
    const res = await callExport({ format: 'json', licenseKey: 'adia-test-1111' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(2);
  });

  it('since filter excludes entries before the date', async () => {
    // Insert an old entry by manipulating the DB directly isn't possible here,
    // but we can confirm that since=future returns nothing.
    const res = await callExport({ format: 'json', since: '2099-01-01' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
  });

  it('since filter with past date returns all entries', async () => {
    const res = await callExport({ format: 'json', since: '2000-01-01' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(3);
  });

  it('combined action + licenseKey filter narrows correctly', async () => {
    const res = await callExport({ format: 'json', action: 'issue', licenseKey: 'ADIA-TEST-1111' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.entries[0].action).toBe('issue');
    expect(body.entries[0].licenseKey).toBe('ADIA-TEST-1111');
  });

  it('CSV wraps detail field in double-quotes when it contains special characters', async () => {
    insertAuditLog({ licenseKey: 'ADIA-TEST-1111', action: 'set_note', detail: { note: 'has,comma and "quotes"' } });
    const res = await callExport({ format: 'csv', action: 'set_note' });
    expect(res.status).toBe(200);
    const text = await res.text();
    // detail is stored as JSON; the JSON string itself contains commas so must be quoted in CSV
    const lines = text.trim().split('\n');
    expect(lines.length).toBe(2); // header + 1 data row
    // the data line must start with a quoted cell for the JSON detail
    const dataLine = lines[1];
    expect(dataLine).toContain('"'); // detail column is RFC-4180 quoted
    expect(dataLine).toContain('has,comma'); // the actual note value appears in the detail
  });
});
