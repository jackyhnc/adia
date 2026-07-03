// Tests for GET /api/admin/audit-log and audit log instrumentation on admin routes.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, listAuditLog } from '@/lib/db';

let dbPath: string;

beforeEach(() => {
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
