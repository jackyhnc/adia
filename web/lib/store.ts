// Storage facade. Picks SQLite (dev/test) or Postgres (production) based on
// DATABASE_URL. Always returns Promises so callers can `await` regardless of
// backend.
//
//   DATABASE_URL=postgres://...  → @vercel/postgres
//   DATABASE_URL=postgresql://... → @vercel/postgres
//   anything else                 → better-sqlite3 (lib/db.ts)

import * as sqlite from './db';
import type { License } from './db';

const usePg = (() => {
  const url = process.env.DATABASE_URL ?? '';
  return /^postgres(ql)?:\/\//.test(url);
})();

export type { License };

export async function insertLicense(row: {
  key: string;
  email: string;
  plan: License['plan'];
  stripeSession?: string;
  stripeSub?: string;
  expiresAt: string | null;
}): Promise<string> {
  if (usePg) {
    const { insertLicensePg } = await import('./db-pg');
    return insertLicensePg(row);
  }
  return sqlite.insertLicense(row);
}

export async function findLicense(key: string, email?: string): Promise<License | null> {
  if (usePg) {
    const { findLicensePg } = await import('./db-pg');
    return findLicensePg(key, email);
  }
  return sqlite.findLicense(key, email);
}

export async function recordActivation(key: string, machineHash: string): Promise<number> {
  if (usePg) {
    const { recordActivationPg } = await import('./db-pg');
    return recordActivationPg(key, machineHash);
  }
  return sqlite.recordActivation(key, machineHash);
}

export async function hasActivation(key: string, machineHash: string): Promise<boolean> {
  if (usePg) {
    const { hasActivationPg } = await import('./db-pg');
    return hasActivationPg(key, machineHash);
  }
  return sqlite.hasActivation(key, machineHash);
}

export async function countActivations(key: string): Promise<number> {
  if (usePg) {
    const { countActivationsPg } = await import('./db-pg');
    return countActivationsPg(key);
  }
  return sqlite.countActivations(key);
}

export async function findLicensesByEmail(email: string): Promise<License[]> {
  if (usePg) {
    const { findLicensesByEmailPg } = await import('./db-pg');
    return findLicensesByEmailPg(email);
  }
  return sqlite.findLicensesByEmail(email);
}

export async function setStatus(key: string, status: License['status']): Promise<void> {
  if (usePg) {
    const { setStatusPg } = await import('./db-pg');
    return setStatusPg(key, status);
  }
  sqlite.setStatus(key, status);
}

export async function setStatusBySub(stripeSub: string, status: License['status']): Promise<void> {
  if (usePg) {
    const { setStatusBySubPg } = await import('./db-pg');
    return setStatusBySubPg(stripeSub, status);
  }
  sqlite.setStatusBySub(stripeSub, status);
}

export async function setExpiryBySub(stripeSub: string, expiresAt: string | null): Promise<void> {
  if (usePg) {
    const { setExpiryBySubPg } = await import('./db-pg');
    return setExpiryBySubPg(stripeSub, expiresAt);
  }
  sqlite.setExpiryBySub(stripeSub, expiresAt);
}

export async function joinWaitlist(email: string): Promise<void> {
  if (usePg) {
    const { joinWaitlistPg } = await import('./db-pg');
    return joinWaitlistPg(email);
  }
  sqlite.joinWaitlist(email);
}
