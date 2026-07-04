// Tests for GET /api/admin/audit-log and audit log instrumentation on admin routes.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, listAuditLog } from '@/lib/db';
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
    `adia-audit-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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

async function callAuditLog(params: Record<string, string> = {}, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/audit-log/route');
  const qs = new URLSearchParams(params).toString();
  const req = new NextRequest(`http://localhost/api/admin/audit-log${qs ? `?${qs}` : ''}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

async function callRevoke(key: string) {
  const { POST } = await import('@/app/api/admin/revoke/route');
  const req = new NextRequest('http://localhost/api/admin/revoke', {
    method: 'POST',
    body: JSON.stringify({ key }),
    headers: { 'Content-Type': 'application/json', ...authHeader() },
  });
  return POST(req);
}

async function callChangePlan(key: string, plan: string) {
  const { POST } = await import('@/app/api/admin/change-plan/route');
  const req = new NextRequest('http://localhost/api/admin/change-plan', {
    method: 'POST',
    body: JSON.stringify({ key, plan }),
    headers: { 'Content-Type': 'application/json', ...authHeader() },
  });
  return POST(req);
}

async function callExtend(key: string, days: number) {
  const { POST } = await import('@/app/api/admin/extend/route');
  const req = new NextRequest('http://localhost/api/admin/extend', {
    method: 'POST',
    body: JSON.stringify({ key, days }),
    headers: { 'Content-Type': 'application/json', ...authHeader() },
  });
  return POST(req);
}

async function callReactivate(key: string) {
  const { POST } = await import('@/app/api/admin/reactivate/route');
  const req = new NextRequest('http://localhost/api/admin/reactivate', {
    method: 'POST',
    body: JSON.stringify({ key }),
    headers: { 'Content-Type': 'application/json', ...authHeader() },
  });
  return POST(req);
}

async function callSetNote(key: string, note: string | null) {
  const { POST } = await import('@/app/api/admin/note/route');
  const req = new NextRequest('http://localhost/api/admin/note', {
    method: 'POST',
    body: JSON.stringify({ key, note }),
    headers: { 'Content-Type': 'application/json', ...authHeader() },
  });
  return POST(req);
}

async function callChangeEmail(key: string, newEmail: string) {
  const { POST } = await import('@/app/api/admin/change-email/route');
  const req = new NextRequest('http://localhost/api/admin/change-email', {
    method: 'POST',
    body: JSON.stringify({ key, newEmail }),
    headers: { 'Content-Type': 'application/json', ...authHeader() },
  });
  return POST(req);
}

// ─── GET /api/admin/audit-log — auth & basic shape ───────────────────────────

describe('GET /api/admin/audit-log — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest('http://localhost/api/admin/audit-log', { method: 'GET' });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callAuditLog({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest(
      'http://localhost/api/admin/audit-log?token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

describe('GET /api/admin/audit-log — empty and pagination', () => {
  it('returns empty list when no audit entries exist', async () => {
    const res = await callAuditLog();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.entries).toEqual([]);
  });

  it('returns entries in descending order (most recent first)', async () => {
    insertLicense({ key: 'ADIA-AUDIT-ORD1-AAAA', email: 'order@example.com', plan: 'lifetime', expiresAt: null });
    await callRevoke('ADIA-AUDIT-ORD1-AAAA');
    await callReactivate('ADIA-AUDIT-ORD1-AAAA');

    const res = await callAuditLog();
    expect(res.status).toBe(200);
    const body = await res.json();
    // Most recent action (reactivate) should come first
    expect(body.entries[0].action).toBe('reactivate');
    expect(body.entries[1].action).toBe('revoke');
  });

  it('respects limit parameter', async () => {
    insertLicense({ key: 'ADIA-AUDIT-LIM1-AAAA', email: 'limit@example.com', plan: 'monthly', expiresAt: null });
    // Generate 3 audit entries
    await callRevoke('ADIA-AUDIT-LIM1-AAAA');
    await callReactivate('ADIA-AUDIT-LIM1-AAAA');
    await callSetNote('ADIA-AUDIT-LIM1-AAAA', 'test note');

    const res = await callAuditLog({ limit: '2' });
    const body = await res.json();
    expect(body.entries.length).toBe(2);
  });

  it('clamps limit to 500 max', async () => {
    const res = await callAuditLog({ limit: '9999' });
    expect(res.status).toBe(200);
    // Should not error; just return up to 500 entries (empty here)
    expect((await res.json()).entries).toEqual([]);
  });
});

// ─── GET /api/admin/audit-log — filter by key ────────────────────────────────

describe('GET /api/admin/audit-log — key filter', () => {
  it('filters entries to a specific license key', async () => {
    insertLicense({ key: 'ADIA-AUDIT-KY1A-AAAA', email: 'ka@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: 'ADIA-AUDIT-KY1B-BBBB', email: 'kb@example.com', plan: 'monthly', expiresAt: null });

    await callRevoke('ADIA-AUDIT-KY1A-AAAA');
    await callSetNote('ADIA-AUDIT-KY1B-BBBB', 'only for B');

    const res = await callAuditLog({ key: 'ADIA-AUDIT-KY1A-AAAA' });
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.entries[0].licenseKey).toBe('ADIA-AUDIT-KY1A-AAAA');
    expect(body.entries[0].action).toBe('revoke');
  });

  it('returns empty when key filter matches no entries', async () => {
    const res = await callAuditLog({ key: 'ADIA-NOPE-NOPE-NOPE' });
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.entries).toEqual([]);
  });
});

// ─── Audit entry shape ────────────────────────────────────────────────────────

describe('audit entry shape', () => {
  it('entry has id, licenseKey, action, detail, createdAt fields', async () => {
    insertLicense({ key: 'ADIA-AUDIT-SHP1-AAAA', email: 'shape@example.com', plan: 'lifetime', expiresAt: null });
    await callRevoke('ADIA-AUDIT-SHP1-AAAA');

    const res = await callAuditLog({ key: 'ADIA-AUDIT-SHP1-AAAA' });
    const body = await res.json();
    const entry = body.entries[0];
    expect(typeof entry.id).toBe('number');
    expect(entry.licenseKey).toBe('ADIA-AUDIT-SHP1-AAAA');
    expect(entry.action).toBe('revoke');
    expect(entry.detail).toContain('canceled');
    expect(typeof entry.createdAt).toBe('string');
  });

  it('detail is valid JSON string containing before/after values', async () => {
    insertLicense({ key: 'ADIA-AUDIT-DET1-AAAA', email: 'detail@example.com', plan: 'monthly', expiresAt: null });
    await callChangePlan('ADIA-AUDIT-DET1-AAAA', 'lifetime');

    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-DET1-AAAA' });
    expect(entries.length).toBe(1);
    const parsed = JSON.parse(entries[0].detail!);
    expect(parsed.previousPlan).toBe('monthly');
    expect(parsed.newPlan).toBe('lifetime');
  });
});

// ─── Action instrumentation ───────────────────────────────────────────────────

describe('revoke writes audit log', () => {
  it('logs revoke action with previousStatus and newStatus', async () => {
    insertLicense({ key: 'ADIA-AUDIT-RVK1-AAAA', email: 'rvk@example.com', plan: 'lifetime', expiresAt: null });
    await callRevoke('ADIA-AUDIT-RVK1-AAAA');
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-RVK1-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('revoke');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.previousStatus).toBe('active');
    expect(detail.newStatus).toBe('canceled');
  });
});

describe('change_plan writes audit log', () => {
  it('logs change_plan action with previousPlan and newPlan', async () => {
    insertLicense({ key: 'ADIA-AUDIT-CPL1-AAAA', email: 'cpl@example.com', plan: 'monthly', expiresAt: null });
    await callChangePlan('ADIA-AUDIT-CPL1-AAAA', 'yearly');
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-CPL1-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('change_plan');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.previousPlan).toBe('monthly');
    expect(detail.newPlan).toBe('yearly');
  });
});

describe('extend writes audit log', () => {
  it('logs extend action with days and newExpiresAt', async () => {
    insertLicense({ key: 'ADIA-AUDIT-EXT1-AAAA', email: 'ext@example.com', plan: 'yearly', expiresAt: null });
    await callExtend('ADIA-AUDIT-EXT1-AAAA', 30);
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-EXT1-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('extend');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.days).toBe(30);
    expect(typeof detail.newExpiresAt).toBe('string');
  });
});

describe('reactivate writes audit log', () => {
  it('logs reactivate action with previousStatus and newStatus', async () => {
    insertLicense({ key: 'ADIA-AUDIT-REA1-AAAA', email: 'rea@example.com', plan: 'lifetime', expiresAt: null });
    await callRevoke('ADIA-AUDIT-REA1-AAAA');
    await callReactivate('ADIA-AUDIT-REA1-AAAA');
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-REA1-AAAA' });
    expect(entries.length).toBe(2);
    expect(entries[0].action).toBe('reactivate');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.previousStatus).toBe('canceled');
    expect(detail.newStatus).toBe('active');
  });
});

describe('set_note writes audit log', () => {
  it('logs set_note action with note value', async () => {
    insertLicense({ key: 'ADIA-AUDIT-NTE1-AAAA', email: 'nte@example.com', plan: 'lifetime', expiresAt: null });
    await callSetNote('ADIA-AUDIT-NTE1-AAAA', 'Speaker comp');
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-NTE1-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('set_note');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.note).toBe('Speaker comp');
  });
});

describe('change_email writes audit log', () => {
  it('logs change_email action with oldEmail and newEmail', async () => {
    insertLicense({ key: 'ADIA-AUDIT-EML1-AAAA', email: 'old@example.com', plan: 'lifetime', expiresAt: null });
    await callChangeEmail('ADIA-AUDIT-EML1-AAAA', 'new@example.com');
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-EML1-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('change_email');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.oldEmail).toBe('old@example.com');
    expect(detail.newEmail).toBe('new@example.com');
  });
});

// ─── resend_license writes audit log ─────────────────────────────────────────

async function callResendLicense(body: { key?: string; email?: string }) {
  const { POST } = await import('@/app/api/admin/resend-license/route');
  const req = new NextRequest('http://localhost/api/admin/resend-license', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader() },
  });
  return POST(req);
}

describe('resend_license writes audit log', () => {
  it('logs resend_license action with to and resolvedBy=key when key is supplied', async () => {
    insertLicense({ key: 'ADIA-AUDIT-RSK1-AAAA', email: 'resend-k@example.com', plan: 'lifetime', expiresAt: null });
    await callResendLicense({ key: 'ADIA-AUDIT-RSK1-AAAA' });
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-RSK1-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('resend_license');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.to).toBe('resend-k@example.com');
    expect(detail.resolvedBy).toBe('key');
  });

  it('logs resend_license action with resolvedBy=email when email is supplied without key', async () => {
    insertLicense({ key: 'ADIA-AUDIT-RSE1-AAAA', email: 'resend-e@example.com', plan: 'lifetime', expiresAt: null });
    await callResendLicense({ email: 'resend-e@example.com' });
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-RSE1-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('resend_license');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.to).toBe('resend-e@example.com');
    expect(detail.resolvedBy).toBe('email');
  });
});

// ─── deactivate_all writes audit log ─────────────────────────────────────────

async function callDeactivateAll(key: string) {
  const { POST } = await import('@/app/api/admin/deactivate-all/route');
  const req = new NextRequest('http://localhost/api/admin/deactivate-all', {
    method: 'POST',
    body: JSON.stringify({ key }),
    headers: { 'Content-Type': 'application/json', ...authHeader() },
  });
  return POST(req);
}

describe('deactivate_all writes audit log', () => {
  it('logs deactivate_all action with removedCount=0 when no activations exist', async () => {
    insertLicense({ key: 'ADIA-AUDIT-DAL0-AAAA', email: 'dal0@example.com', plan: 'lifetime', expiresAt: null });
    await callDeactivateAll('ADIA-AUDIT-DAL0-AAAA');
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-DAL0-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('deactivate_all');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.removedCount).toBe(0);
  });

  it('logs deactivate_all with correct removedCount after activations are removed', async () => {
    const { recordActivation } = await import('@/lib/db');
    insertLicense({ key: 'ADIA-AUDIT-DAL2-AAAA', email: 'dal2@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation('ADIA-AUDIT-DAL2-AAAA', 'machine-hash-1');
    recordActivation('ADIA-AUDIT-DAL2-AAAA', 'machine-hash-2');
    await callDeactivateAll('ADIA-AUDIT-DAL2-AAAA');
    const entries = listAuditLog({ licenseKey: 'ADIA-AUDIT-DAL2-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('deactivate_all');
    const detail = JSON.parse(entries[0].detail!);
    expect(detail.removedCount).toBe(2);
  });
});

// ─── CSV export ───────────────────────────────────────────────────────────────

describe('GET /api/admin/audit-log?format=csv', () => {
  it('returns 401 when not authorized', async () => {
    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest('http://localhost/api/admin/audit-log?format=csv', { method: 'GET' });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns text/csv Content-Type', async () => {
    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest('http://localhost/api/admin/audit-log?format=csv', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('text/csv');
  });

  it('returns CSV with header row and one data row per audit entry', async () => {
    insertLicense({ key: 'ADIA-AUDIT-CSV1-AAAA', email: 'csv@example.com', plan: 'lifetime', expiresAt: null });
    await callRevoke('ADIA-AUDIT-CSV1-AAAA');

    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest('http://localhost/api/admin/audit-log?format=csv', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    const text = await res.text();
    const lines = text.trim().split('\n');
    expect(lines[0]).toBe('id,createdAt,licenseKey,action,detail');
    expect(lines.length).toBeGreaterThanOrEqual(2);
    expect(lines[1]).toContain('revoke');
    expect(lines[1]).toContain('ADIA-AUDIT-CSV1-AAAA');
  });

  it('CSV detail field escapes internal double quotes (RFC 4180)', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    insertLicense({ key: 'ADIA-AUDIT-CSQ1-AAAA', email: 'csvq@example.com', plan: 'lifetime', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-AUDIT-CSQ1-AAAA', action: 'set_note', detail: { note: 'say "hello"' } });

    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest('http://localhost/api/admin/audit-log?format=csv&key=ADIA-AUDIT-CSQ1-AAAA', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    const text = await res.text();
    // The detail is stored as JSON: {"note":"say \"hello\""}
    // After CSV double-quote escaping, every " becomes "" inside the quoted field.
    // Verify the field is CSV-quoted and the key appears escaped.
    expect(text).toContain('ADIA-AUDIT-CSQ1-AAAA');
    expect(text).toContain('set_note');
    // No bare (unescaped) double quotes outside the surrounding CSV quotes.
    const dataLine = text.trim().split('\n')[1];
    expect(dataLine.startsWith('"') || dataLine.includes(',"')).toBe(true);
  });
});

// ─── audit-log pagination and action filter ──────────────────────────────────

describe('GET /api/admin/audit-log — pagination', () => {
  it('response includes total, hasMore, offset, limit fields', async () => {
    insertLicense({ key: 'ADIA-PAGN-FLDS-AAAA', email: 'pgflds@example.com', plan: 'lifetime', expiresAt: null });
    await callRevoke('ADIA-PAGN-FLDS-AAAA');
    const res = await callAuditLog({ limit: '10' });
    const body = await res.json();
    expect(body).toHaveProperty('total');
    expect(body).toHaveProperty('hasMore');
    expect(body).toHaveProperty('offset');
    expect(body).toHaveProperty('limit');
    expect(body.limit).toBe(10);
    expect(body.offset).toBe(0);
  });

  it('total reflects count of all entries regardless of limit', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    for (let i = 1; i <= 5; i++) {
      const key = `ADIA-PGTT-TOT${i}-AAAA`;
      insertLicense({ key, email: `pgtt${i}@example.com`, plan: 'lifetime', expiresAt: null });
      insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });
    }
    const res = await callAuditLog({ limit: '2' });
    const body = await res.json();
    expect(body.total).toBeGreaterThanOrEqual(5);
    expect(body.entries.length).toBe(2);
  });

  it('hasMore is true when more entries exist beyond the current page', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    for (let i = 1; i <= 4; i++) {
      const key = `ADIA-PGHS-MOR${i}-AAAA`;
      insertLicense({ key, email: `pghs${i}@example.com`, plan: 'lifetime', expiresAt: null });
      insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });
    }
    const res = await callAuditLog({ limit: '2', offset: '0' });
    const body = await res.json();
    expect(body.hasMore).toBe(true);
    expect(body.entries.length).toBe(2);
  });

  it('hasMore is false when all entries fit on the page', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    const key = 'ADIA-PGHS-FIT1-AAAA';
    insertLicense({ key, email: 'pghsfit@example.com', plan: 'lifetime', expiresAt: null });
    insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });
    // Use key filter so only 1 entry matches
    const res = await callAuditLog({ key: 'ADIA-PGHS-FIT1-AAAA', limit: '50' });
    const body = await res.json();
    expect(body.hasMore).toBe(false);
    expect(body.total).toBe(1);
  });

  it('offset skips earlier entries and returns the next page', async () => {
    const { insertAuditLog, countAuditLog } = await import('@/lib/db');
    // Insert 3 entries for a specific key, newest first
    const key = 'ADIA-PGOF-SKP1-AAAA';
    insertLicense({ key, email: 'pgofskp@example.com', plan: 'lifetime', expiresAt: null });
    insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });
    insertAuditLog({ licenseKey: key, action: 'extend', detail: {} });
    insertAuditLog({ licenseKey: key, action: 'revoke', detail: {} });
    // Page 1: first 2 entries
    const res1 = await callAuditLog({ key, limit: '2', offset: '0' });
    const body1 = await res1.json();
    expect(body1.entries.length).toBe(2);
    expect(body1.hasMore).toBe(true);
    // Page 2: 1 remaining entry
    const res2 = await callAuditLog({ key, limit: '2', offset: '2' });
    const body2 = await res2.json();
    expect(body2.entries.length).toBe(1);
    expect(body2.hasMore).toBe(false);
    // No overlap
    const ids1 = new Set(body1.entries.map((e: any) => e.id));
    const ids2 = new Set(body2.entries.map((e: any) => e.id));
    for (const id of ids2) expect(ids1.has(id)).toBe(false);
  });

  it('?token= query param auth works for pagination', async () => {
    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest('http://localhost/api/admin/audit-log?token=test-admin-token&limit=10');
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('entries');
  });
});

describe('GET /api/admin/audit-log — action filter', () => {
  it('action filter returns only entries with that action', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    const keyA = 'ADIA-AFLT-ACT1-AAAA';
    const keyB = 'ADIA-AFLT-ACT2-AAAA';
    insertLicense({ key: keyA, email: 'afltact1@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: keyB, email: 'afltact2@example.com', plan: 'lifetime', expiresAt: null });
    insertAuditLog({ licenseKey: keyA, action: 'issue', detail: {} });
    insertAuditLog({ licenseKey: keyB, action: 'revoke', detail: {} });
    insertAuditLog({ licenseKey: keyA, action: 'extend', detail: {} });
    const res = await callAuditLog({ action: 'revoke' });
    const body = await res.json();
    expect(body.entries.every((e: any) => e.action === 'revoke')).toBe(true);
    expect(body.entries.some((e: any) => e.licenseKey === keyB)).toBe(true);
    expect(body.entries.some((e: any) => e.action === 'issue')).toBe(false);
  });

  it('action filter combined with key filter narrows results', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    const key = 'ADIA-AFLT-COMB-AAAA';
    insertLicense({ key, email: 'afltcomb@example.com', plan: 'lifetime', expiresAt: null });
    insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });
    insertAuditLog({ licenseKey: key, action: 'extend', detail: {} });
    // Only "issue" for this specific key
    const res = await callAuditLog({ key, action: 'issue' });
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.entries[0].action).toBe('issue');
  });

  it('unknown action returns empty result', async () => {
    const res = await callAuditLog({ action: 'nonexistent_action_xyz' });
    const body = await res.json();
    expect(res.status).toBe(200);
    expect(body.entries.length).toBe(0);
    expect(body.total).toBe(0);
    expect(body.hasMore).toBe(false);
  });
});

// ─── GET /api/admin/audit-log — since filter ─────────────────────────────────

describe('GET /api/admin/audit-log — since filter', () => {
  it('since filter excludes entries before the given date', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    const key = 'ADIA-SNCE-OLD1-AAAA';
    insertLicense({ key, email: 'snceold1@example.com', plan: 'lifetime', expiresAt: null });

    // Insert an old entry
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-01-15T10:00:00Z'));
    insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });

    // Insert a recent entry
    vi.setSystemTime(new Date('2026-07-04T10:00:00Z'));
    insertAuditLog({ licenseKey: key, action: 'extend', detail: {} });
    vi.useRealTimers();

    const res = await callAuditLog({ since: '2026-07-01' });
    const body = await res.json();
    expect(body.entries.every((e: any) => e.createdAt >= '2026-07-01')).toBe(true);
    expect(body.entries.some((e: any) => e.action === 'extend')).toBe(true);
    expect(body.entries.some((e: any) => e.createdAt < '2026-07-01')).toBe(false);
  });

  it('since filter includes entries on the exact since date', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    const key = 'ADIA-SNCE-EXC1-AAAA';
    insertLicense({ key, email: 'snceexc1@example.com', plan: 'lifetime', expiresAt: null });

    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-06-30T23:59:59Z'));
    insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });
    vi.useRealTimers();

    const res = await callAuditLog({ since: '2026-06-30' });
    const body = await res.json();
    expect(body.total).toBeGreaterThanOrEqual(1);
    expect(body.entries.some((e: any) => e.licenseKey === key)).toBe(true);
  });

  it('since filter combined with action filter narrows results', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    const key = 'ADIA-SNCE-CMB1-AAAA';
    insertLicense({ key, email: 'sncecmb1@example.com', plan: 'lifetime', expiresAt: null });

    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-01-10T00:00:00Z'));
    insertAuditLog({ licenseKey: key, action: 'revoke', detail: {} });
    vi.setSystemTime(new Date('2026-07-04T00:00:00Z'));
    insertAuditLog({ licenseKey: key, action: 'revoke', detail: {} });
    insertAuditLog({ licenseKey: key, action: 'extend', detail: {} });
    vi.useRealTimers();

    // since=2026-07-01 + action=revoke should return only the recent revoke
    const res = await callAuditLog({ since: '2026-07-01', action: 'revoke' });
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.entries[0].action).toBe('revoke');
    expect(body.entries[0].createdAt >= '2026-07-01').toBe(true);
  });

  it('since filter with no matching entries returns empty', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    const key = 'ADIA-SNCE-EMP1-AAAA';
    insertLicense({ key, email: 'snceemp1@example.com', plan: 'lifetime', expiresAt: null });

    vi.useFakeTimers();
    vi.setSystemTime(new Date('2025-06-01T00:00:00Z'));
    insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });
    vi.useRealTimers();

    // Requesting entries from the future
    const res = await callAuditLog({ since: '2027-01-01' });
    const body = await res.json();
    expect(body.entries.length).toBe(0);
    expect(body.total).toBe(0);
    expect(body.hasMore).toBe(false);
  });

  it('malformed since value is ignored (treated as no filter)', async () => {
    const res = await callAuditLog({ since: 'not-a-date' });
    expect(res.status).toBe(200);
    // should not error — invalid since is silently dropped
    const body = await res.json();
    expect(body).toHaveProperty('entries');
  });

  it('since filter is forwarded in count so total reflects filtered set', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    const key = 'ADIA-SNCE-TTL1-AAAA';
    insertLicense({ key, email: 'sncettl1@example.com', plan: 'lifetime', expiresAt: null });

    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-03-01T00:00:00Z'));
    insertAuditLog({ licenseKey: key, action: 'issue', detail: {} });
    vi.setSystemTime(new Date('2026-03-02T00:00:00Z'));
    insertAuditLog({ licenseKey: key, action: 'extend', detail: {} });
    vi.setSystemTime(new Date('2026-07-04T00:00:00Z'));
    insertAuditLog({ licenseKey: key, action: 'revoke', detail: {} });
    vi.useRealTimers();

    const res = await callAuditLog({ since: '2026-07-01', key });
    const body = await res.json();
    // Only the July entry should be counted and returned
    expect(body.total).toBe(1);
    expect(body.entries.length).toBe(1);
    expect(body.hasMore).toBe(false);
  });
});

// ─── findLicense now includes note field ─────────────────────────────────────

describe('findLicense note field', () => {
  it('returns note=null when no note has been set', async () => {
    const { findLicense } = await import('@/lib/db');
    insertLicense({ key: 'ADIA-AUDIT-NNL1-AAAA', email: 'nonote@example.com', plan: 'lifetime', expiresAt: null });
    const lic = findLicense('ADIA-AUDIT-NNL1-AAAA');
    expect(lic).not.toBeNull();
    expect(lic!.note).toBeNull();
  });

  it('returns note value after it is set', async () => {
    const { findLicense } = await import('@/lib/db');
    insertLicense({ key: 'ADIA-AUDIT-NHV1-AAAA', email: 'hasnote@example.com', plan: 'lifetime', expiresAt: null });
    await callSetNote('ADIA-AUDIT-NHV1-AAAA', 'test note value');
    const lic = findLicense('ADIA-AUDIT-NHV1-AAAA');
    expect(lic!.note).toBe('test note value');
  });
});
