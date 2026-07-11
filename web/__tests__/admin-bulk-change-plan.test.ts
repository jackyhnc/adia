import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, findLicense, insertLicense, listAuditLog, setPlan } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-change-plan-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callBulkChangePlan(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-change-plan', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  return POST(req);
}

function seedLicense(
  key: string,
  email = 'owner@example.com',
  plan: 'lifetime' | 'monthly' | 'yearly' = 'monthly',
) {
  insertLicense({ key, email, plan, expiresAt: null });
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-plan — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-change-plan', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-BCP-AUTH-0001'], plan: 'yearly' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-AUTH-0002'], plan: 'yearly' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    seedLicense('ADIA-BCP-AUTH-0003', 'user@example.com', 'monthly');
    const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-change-plan?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BCP-AUTH-0003'], plan: 'yearly' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-plan — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callBulkChangePlan({ plan: 'yearly' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys is empty', async () => {
    const res = await callBulkChangePlan({ keys: [], plan: 'yearly' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BCP-VAL-${String(i).padStart(4, '0')}`);
    const res = await callBulkChangePlan({ keys, plan: 'yearly' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/100/);
  });

  it('returns 400 when plan is missing', async () => {
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-VAL-0001'] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/plan/);
  });

  it('returns 400 for an invalid plan value', async () => {
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-VAL-0002'], plan: 'enterprise' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/plan/);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-plan — core behavior', () => {
  it('changes plan for a single key', async () => {
    seedLicense('ADIA-BCP-CORE-0001', 'user@example.com', 'monthly');
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-CORE-0001'], plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.plan).toBe('yearly');
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BCP-CORE-0001');
    expect(body.skipped).toHaveLength(0);
    expect(findLicense('ADIA-BCP-CORE-0001')?.plan).toBe('yearly');
  });

  it('changes plan for multiple keys in one request', async () => {
    seedLicense('ADIA-BCP-CORE-0002', 'user@example.com', 'monthly');
    seedLicense('ADIA-BCP-CORE-0003', 'user@example.com', 'monthly');
    seedLicense('ADIA-BCP-CORE-0004', 'user@example.com', 'monthly');
    const res = await callBulkChangePlan({
      keys: ['ADIA-BCP-CORE-0002', 'ADIA-BCP-CORE-0003', 'ADIA-BCP-CORE-0004'],
      plan: 'lifetime',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    for (const key of ['ADIA-BCP-CORE-0002', 'ADIA-BCP-CORE-0003', 'ADIA-BCP-CORE-0004']) {
      expect(findLicense(key)?.plan).toBe('lifetime');
    }
  });

  it('normalizes keys to uppercase', async () => {
    seedLicense('ADIA-BCP-CORE-0005', 'user@example.com', 'monthly');
    const res = await callBulkChangePlan({ keys: ['adia-bcp-core-0005'], plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].key).toBe('ADIA-BCP-CORE-0005');
    expect(findLicense('ADIA-BCP-CORE-0005')?.plan).toBe('yearly');
  });

  it('returns previousPlan in changed entry when upgrading monthly→yearly', async () => {
    seedLicense('ADIA-BCP-CORE-0006', 'user@example.com', 'monthly');
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-CORE-0006'], plan: 'yearly' });
    const body = await res.json();
    expect(body.changed[0].previousPlan).toBe('monthly');
  });

  it('returns previousPlan=yearly when upgrading yearly→lifetime', async () => {
    seedLicense('ADIA-BCP-CORE-0007', 'user@example.com', 'yearly');
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-CORE-0007'], plan: 'lifetime' });
    const body = await res.json();
    expect(body.changed[0].previousPlan).toBe('yearly');
  });

  it('returns previousPlan=lifetime when downgrading lifetime→monthly', async () => {
    seedLicense('ADIA-BCP-CORE-0008', 'user@example.com', 'lifetime');
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-CORE-0008'], plan: 'monthly' });
    const body = await res.json();
    expect(body.changed[0].previousPlan).toBe('lifetime');
    expect(findLicense('ADIA-BCP-CORE-0008')?.plan).toBe('monthly');
  });

  it('response includes the target plan field', async () => {
    seedLicense('ADIA-BCP-CORE-0009', 'user@example.com', 'monthly');
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-CORE-0009'], plan: 'lifetime' });
    const body = await res.json();
    expect(body.plan).toBe('lifetime');
  });
});

// ─── Skip behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-plan — skip behavior', () => {
  it('skips unknown keys with reason=not_found', async () => {
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-SKIP-0001'], plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BCP-SKIP-0001');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('skips keys already on the target plan with reason=already_on_plan', async () => {
    seedLicense('ADIA-BCP-SKIP-0002', 'user@example.com', 'yearly');
    const res = await callBulkChangePlan({ keys: ['ADIA-BCP-SKIP-0002'], plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BCP-SKIP-0002');
    expect(body.skipped[0].reason).toBe('already_on_plan');
  });

  it('handles mixed changed + skipped in one request', async () => {
    seedLicense('ADIA-BCP-SKIP-0003', 'user@example.com', 'monthly');
    seedLicense('ADIA-BCP-SKIP-0004', 'user@example.com', 'lifetime');
    // ADIA-BCP-SKIP-0005 does not exist → not_found
    const res = await callBulkChangePlan({
      keys: ['ADIA-BCP-SKIP-0003', 'ADIA-BCP-SKIP-0004', 'ADIA-BCP-SKIP-0005'],
      plan: 'lifetime',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BCP-SKIP-0003');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: { reason: string }) => s.reason);
    expect(reasons).toContain('already_on_plan');
    expect(reasons).toContain('not_found');
  });

  it('does not mutate a skipped (already_on_plan) key', async () => {
    seedLicense('ADIA-BCP-SKIP-0006', 'user@example.com', 'lifetime');
    await callBulkChangePlan({ keys: ['ADIA-BCP-SKIP-0006'], plan: 'lifetime' });
    expect(findLicense('ADIA-BCP-SKIP-0006')?.plan).toBe('lifetime');
  });
});

// ─── Audit log ────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-plan — audit log', () => {
  it('writes one audit log entry per changed key', async () => {
    seedLicense('ADIA-BCP-AUDT-0001', 'user@example.com', 'monthly');
    seedLicense('ADIA-BCP-AUDT-0002', 'user@example.com', 'monthly');
    await callBulkChangePlan({
      keys: ['ADIA-BCP-AUDT-0001', 'ADIA-BCP-AUDT-0002'],
      plan: 'yearly',
    });
    for (const key of ['ADIA-BCP-AUDT-0001', 'ADIA-BCP-AUDT-0002']) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('change_plan');
    }
  });

  it('audit log detail contains previousPlan, newPlan, and bulk=true', async () => {
    seedLicense('ADIA-BCP-AUDT-0003', 'user@example.com', 'monthly');
    await callBulkChangePlan({ keys: ['ADIA-BCP-AUDT-0003'], plan: 'lifetime' });
    const logs = listAuditLog({ licenseKey: 'ADIA-BCP-AUDT-0003' });
    const detail =
      typeof logs[0].detail === 'string' ? JSON.parse(logs[0].detail) : logs[0].detail;
    expect(detail).toMatchObject({
      previousPlan: 'monthly',
      newPlan: 'lifetime',
      bulk: true,
    });
  });

  it('does not write audit log for not_found keys', async () => {
    await callBulkChangePlan({ keys: ['ADIA-BCP-AUDT-NONE'], plan: 'yearly' });
    const logs = listAuditLog({ licenseKey: 'ADIA-BCP-AUDT-NONE' });
    expect(logs).toHaveLength(0);
  });

  it('does not write audit log for already_on_plan keys', async () => {
    seedLicense('ADIA-BCP-AUDT-0004', 'user@example.com', 'yearly');
    await callBulkChangePlan({ keys: ['ADIA-BCP-AUDT-0004'], plan: 'yearly' });
    const logs = listAuditLog({ licenseKey: 'ADIA-BCP-AUDT-0004' });
    expect(logs).toHaveLength(0);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-plan — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
    const ip = '10.98.2.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-change-plan', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      const res = await POST(req);
      lastStatus = res.status;
    }
    expect(lastStatus).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
    const ip = '10.98.2.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-change-plan', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      lastRes = await POST(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
    const ip = '10.98.2.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-change-plan', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      await POST(req);
    }
    const req = new NextRequest('http://localhost/api/admin/bulk-change-plan', {
      method: 'POST',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
      body: JSON.stringify({}),
    });
    const res = await POST(req);
    expect(res.status).toBe(429);
  });
});
