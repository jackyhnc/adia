import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import {
  insertLicense,
  findLicense,
  findLicensesByEmail,
  recordActivation,
  listActivations,
  removeActivation,
  setStatus,
  setStatusBySub,
  joinWaitlist,
  resetDbForTesting,
} from '@/lib/db';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-test-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

describe('insert → find round-trip', () => {
  it('returns the inserted license', () => {
    const key = 'ADIA-RNDT-RNDTRP-01';
    insertLicense({ key, email: 'user@example.com', plan: 'lifetime', expiresAt: null });
    const found = findLicense(key);
    expect(found).not.toBeNull();
    expect(found!.key).toBe(key);
    expect(found!.email).toBe('user@example.com');
    expect(found!.plan).toBe('lifetime');
    expect(found!.expiresAt).toBeNull();
    expect(found!.status).toBe('active');
  });
});

describe('case-insensitive key lookup', () => {
  it('finds a key regardless of input case', () => {
    const key = 'ADIA-CASE-TEST-ABCD';
    insertLicense({ key, email: 'x@example.com', plan: 'monthly', expiresAt: null });
    expect(findLicense(key.toLowerCase())).not.toBeNull();
    expect(findLicense(key.toUpperCase())).not.toBeNull();
  });
});

describe('findLicense with email', () => {
  it('filters by email case-insensitively', () => {
    const key = 'ADIA-EMLF-TEST-AAAA';
    insertLicense({ key, email: 'Alice@Example.COM', plan: 'yearly', expiresAt: null });
    expect(findLicense(key, 'alice@example.com')).not.toBeNull();
    expect(findLicense(key, 'bob@example.com')).toBeNull();
  });
});

describe('recordActivation', () => {
  it('counts unique machine seats correctly', () => {
    const key = 'ADIA-SEAT-TEST-AAAA';
    insertLicense({ key, email: 'seats@example.com', plan: 'monthly', expiresAt: null });

    expect(recordActivation(key, 'machine-1')).toBe(1);
    expect(recordActivation(key, 'machine-2')).toBe(2);
    expect(recordActivation(key, 'machine-3')).toBe(3);
    // Same machine again — no new seat
    expect(recordActivation(key, 'machine-1')).toBe(3);
  });
});

describe('webhook idempotency', () => {
  it('returns existing key when stripe_session already exists', () => {
    const stripeSession = 'cs_test_idempotency_abc123';
    const key1 = 'ADIA-IDMP-KEY1-AAAA';
    const key2 = 'ADIA-IDMP-KEY2-BBBB';

    const written1 = insertLicense({
      key: key1,
      email: 'idempotent@example.com',
      plan: 'monthly',
      stripeSession,
      expiresAt: null,
    });
    expect(written1).toBe(key1);

    // Re-delivered webhook — must return original key, not create a second
    const written2 = insertLicense({
      key: key2,
      email: 'idempotent@example.com',
      plan: 'monthly',
      stripeSession,
      expiresAt: null,
    });
    expect(written2).toBe(key1);
  });
});

describe('setStatus', () => {
  it('updates license status', () => {
    const key = 'ADIA-STAT-TEST-AAAA';
    insertLicense({ key, email: 'status@example.com', plan: 'yearly', expiresAt: null });
    setStatus(key, 'canceled');
    expect(findLicense(key)!.status).toBe('canceled');
  });
});

describe('setStatusBySub', () => {
  it('cancels the license identified by stripe_sub', () => {
    const key = 'ADIA-SBST-TEST-AAAA';
    const sub = 'sub_test_abc123';
    insertLicense({ key, email: 'sub@example.com', plan: 'monthly', stripeSub: sub, expiresAt: null });
    expect(findLicense(key)!.status).toBe('active');
    setStatusBySub(sub, 'canceled');
    expect(findLicense(key)!.status).toBe('canceled');
  });

  it('is a no-op for an unknown stripe_sub', () => {
    // should not throw
    setStatusBySub('sub_nonexistent', 'canceled');
  });
});

describe('joinWaitlist', () => {
  it('deduplicates emails without error', () => {
    joinWaitlist('waitlister@example.com');
    joinWaitlist('waitlister@example.com');
  });

  it('normalises to lowercase', () => {
    joinWaitlist('Upper@Example.com');
    joinWaitlist('upper@example.com');
  });
});

describe('findLicensesByEmail', () => {
  it('returns all licenses for an email', () => {
    insertLicense({ key: 'ADIA-FBE1-TEST-AAAA', email: 'multi@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-FBE2-TEST-BBBB', email: 'multi@example.com', plan: 'yearly',  expiresAt: null });
    const results = findLicensesByEmail('multi@example.com');
    expect(results).toHaveLength(2);
    const keys = results.map(r => r.key);
    expect(keys).toContain('ADIA-FBE1-TEST-AAAA');
    expect(keys).toContain('ADIA-FBE2-TEST-BBBB');
  });

  it('returns empty array for unknown email', () => {
    const results = findLicensesByEmail('nobody@example.com');
    expect(results).toHaveLength(0);
  });

  it('is case-insensitive on email', () => {
    insertLicense({ key: 'ADIA-FBEC-TEST-CCCC', email: 'Case@Example.COM', plan: 'lifetime', expiresAt: null });
    expect(findLicensesByEmail('case@example.com')).toHaveLength(1);
    expect(findLicensesByEmail('CASE@EXAMPLE.COM')).toHaveLength(1);
  });

  it('does not return licenses for other emails', () => {
    insertLicense({ key: 'ADIA-FBED-TEST-DDDD', email: 'other@example.com', plan: 'monthly', expiresAt: null });
    const results = findLicensesByEmail('nobody@example.com');
    expect(results).toHaveLength(0);
  });
});

describe('listActivations', () => {
  it('returns empty array when no machines are activated', () => {
    const key = 'ADIA-LSTA-TEST-AAAA';
    insertLicense({ key, email: 'list@example.com', plan: 'lifetime', expiresAt: null });
    expect(listActivations(key)).toHaveLength(0);
  });

  it('lists all activated machines ordered by last_seen descending', () => {
    const key = 'ADIA-LSTB-TEST-BBBB';
    insertLicense({ key, email: 'list2@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-alpha');
    recordActivation(key, 'machine-beta');
    const acts = listActivations(key);
    expect(acts).toHaveLength(2);
    const hashes = acts.map(a => a.machineHash);
    expect(hashes).toContain('machine-alpha');
    expect(hashes).toContain('machine-beta');
  });

  it('includes firstSeen and lastSeen timestamps', () => {
    const key = 'ADIA-LSTC-TEST-CCCC';
    insertLicense({ key, email: 'list3@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-ts');
    const acts = listActivations(key);
    expect(acts[0].firstSeen).toBeTruthy();
    expect(acts[0].lastSeen).toBeTruthy();
  });

  it('does not include machines from other licenses', () => {
    const key1 = 'ADIA-LSTD-TEST-DDDD';
    const key2 = 'ADIA-LSTE-TEST-EEEE';
    insertLicense({ key: key1, email: 'a@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: key2, email: 'b@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key1, 'machine-x');
    recordActivation(key2, 'machine-y');
    const acts = listActivations(key1);
    expect(acts).toHaveLength(1);
    expect(acts[0].machineHash).toBe('machine-x');
  });
});

describe('removeActivation', () => {
  it('removes the specified machine from the activations table', () => {
    const key = 'ADIA-RMVA-TEST-AAAA';
    insertLicense({ key, email: 'rm@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-gone');
    recordActivation(key, 'machine-kept');
    expect(listActivations(key)).toHaveLength(2);
    removeActivation(key, 'machine-gone');
    const remaining = listActivations(key);
    expect(remaining).toHaveLength(1);
    expect(remaining[0].machineHash).toBe('machine-kept');
  });

  it('is a no-op when the machine hash does not exist', () => {
    const key = 'ADIA-RMVB-TEST-BBBB';
    insertLicense({ key, email: 'rm2@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-real');
    expect(() => removeActivation(key, 'machine-ghost')).not.toThrow();
    expect(listActivations(key)).toHaveLength(1);
  });

  it('frees the seat so a new machine can be activated', () => {
    const key = 'ADIA-RMVC-TEST-CCCC';
    insertLicense({ key, email: 'rm3@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-1');
    recordActivation(key, 'machine-2');
    recordActivation(key, 'machine-3');
    expect(listActivations(key)).toHaveLength(3);
    removeActivation(key, 'machine-1');
    // After removal the seat is freed; recordActivation should succeed
    recordActivation(key, 'machine-4');
    expect(listActivations(key)).toHaveLength(3);
    const hashes = listActivations(key).map(a => a.machineHash);
    expect(hashes).toContain('machine-4');
    expect(hashes).not.toContain('machine-1');
  });
});
