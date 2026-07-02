'use client';

import { useState } from 'react';

// ─── Types ──────────────────────────────────────────────────────────────────

type Seat = {
  machineHash: string;
  firstSeen: string;
  lastSeen: string;
};

type LicenseInfo = {
  key: string;
  plan: string;
  status: string;
  seatCount: number;
  seats: Seat[];
};

// ─── Helpers ────────────────────────────────────────────────────────────────

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

function planLabel(plan: string): string {
  if (plan === 'monthly') return 'Monthly';
  if (plan === 'yearly') return 'Yearly';
  if (plan === 'lifetime') return 'Lifetime';
  return plan.charAt(0).toUpperCase() + plan.slice(1);
}

function statusBadge(status: string) {
  const styles: Record<string, string> = {
    active: 'bg-green-100 text-green-800',
    canceled: 'bg-gray-100 text-gray-700',
    expired: 'bg-red-100 text-red-700',
    past_due: 'bg-amber-100 text-amber-800',
  };
  const cls = styles[status] ?? 'bg-gray-100 text-gray-700';
  return (
    <span className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${cls}`}>
      {status.replace('_', ' ')}
    </span>
  );
}

// ─── Lookup form ─────────────────────────────────────────────────────────────

function LookupForm({ onFound }: { onFound: (key: string, email: string, info: LicenseInfo) => void }) {
  const [key, setKey] = useState('');
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const params = new URLSearchParams({ key: key.trim().toUpperCase(), email: email.trim().toLowerCase() });
    const res = await fetch(`/api/license/seats?${params}`);
    if (res.ok) {
      const data: LicenseInfo = await res.json();
      onFound(key.trim().toUpperCase(), email.trim().toLowerCase(), data);
    } else {
      const body = await res.json().catch(() => ({}));
      setError(body.error ?? `Error ${res.status}`);
    }
    setLoading(false);
  }

  return (
    <form onSubmit={handleSubmit} className="card mt-8 space-y-4">
      <div>
        <label className="block text-xs uppercase tracking-wide text-ink/60 mb-1">License key</label>
        <input
          type="text"
          required
          value={key}
          onChange={(e) => setKey(e.target.value)}
          placeholder="ADIA-XXXX-XXXX-XXXX"
          className="input font-mono"
          autoComplete="off"
          spellCheck={false}
        />
      </div>
      <div>
        <label className="block text-xs uppercase tracking-wide text-ink/60 mb-1">Email</label>
        <input
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@example.com"
          className="input"
        />
      </div>
      <button type="submit" className="btn-primary" disabled={loading}>
        {loading ? 'Looking up…' : 'View license →'}
      </button>
      {error && <p className="text-sm text-red-600">{error}</p>}
    </form>
  );
}

// ─── License dashboard ───────────────────────────────────────────────────────

function Dashboard({
  licenseKey,
  email,
  info,
  onRefresh,
  onReset,
}: {
  licenseKey: string;
  email: string;
  info: LicenseInfo;
  onRefresh: () => Promise<void>;
  onReset: () => void;
}) {
  const [removingHash, setRemovingHash] = useState<string | null>(null);
  const [removeError, setRemoveError] = useState<string | null>(null);

  // Transfer email state
  const [showTransfer, setShowTransfer] = useState(false);
  const [newEmail, setNewEmail] = useState('');
  const [transferring, setTransferring] = useState(false);
  const [transferError, setTransferError] = useState<string | null>(null);
  const [transferDone, setTransferDone] = useState(false);

  async function removeMachine(machineHash: string) {
    setRemovingHash(machineHash);
    setRemoveError(null);
    const res = await fetch('/api/license/deactivate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: licenseKey, email, machine: machineHash }),
    });
    if (res.ok) {
      await onRefresh();
    } else {
      const body = await res.json().catch(() => ({}));
      setRemoveError(body.error ?? `Error ${res.status}`);
    }
    setRemovingHash(null);
  }

  async function handleTransfer(e: React.FormEvent) {
    e.preventDefault();
    setTransferring(true);
    setTransferError(null);
    const res = await fetch('/api/license/transfer', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: licenseKey, email, newEmail: newEmail.trim().toLowerCase() }),
    });
    if (res.ok) {
      setTransferDone(true);
    } else {
      const body = await res.json().catch(() => ({}));
      setTransferError(body.error ?? `Error ${res.status}`);
    }
    setTransferring(false);
  }

  if (transferDone) {
    return (
      <div className="card mt-8 space-y-4">
        <h2 className="text-lg font-semibold">Email updated</h2>
        <p className="text-ink/70">
          Your license is now registered to <strong>{newEmail.trim().toLowerCase()}</strong>.
          Use your new email to look up this license going forward.
        </p>
        <button onClick={onReset} className="btn-secondary">Back to lookup</button>
      </div>
    );
  }

  return (
    <div className="space-y-6 mt-8">
      {/* License summary */}
      <div className="card space-y-4">
        <div className="flex items-start justify-between gap-4">
          <div>
            <div className="text-xs uppercase tracking-wide text-ink/60 mb-1">License</div>
            <div className="font-mono text-lg select-all">{licenseKey}</div>
            <div className="mt-1 text-sm text-ink/60">{email}</div>
          </div>
          <div className="text-right">
            {statusBadge(info.status)}
            <div className="mt-1 text-sm text-ink/70">{planLabel(info.plan)}</div>
          </div>
        </div>
        <div className="text-sm text-ink/60">
          {info.seatCount === 0
            ? 'No machines activated.'
            : `${info.seatCount} machine${info.seatCount === 1 ? '' : 's'} activated.`}
        </div>
        <button onClick={onReset} className="btn-secondary text-xs py-1.5 px-3">
          Look up a different license
        </button>
      </div>

      {/* Activated machines */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold">Activated machines</h2>
          <button
            onClick={onRefresh}
            className="text-xs text-ink/50 hover:text-ink transition"
            title="Refresh seat list"
          >
            ↺ Refresh
          </button>
        </div>

        {info.seats.length === 0 ? (
          <p className="text-sm text-ink/60">No machines currently activated.</p>
        ) : (
          <ul className="divide-y divide-ink/5">
            {info.seats.map((seat) => (
              <li key={seat.machineHash} className="py-3 flex items-center justify-between gap-4">
                <div>
                  <div className="font-mono text-sm text-ink/80">{seat.machineHash.slice(0, 16)}&hellip;</div>
                  <div className="text-xs text-ink/50 mt-0.5">
                    Last seen {formatDate(seat.lastSeen)} · First activated {formatDate(seat.firstSeen)}
                  </div>
                </div>
                <button
                  onClick={() => removeMachine(seat.machineHash)}
                  disabled={removingHash === seat.machineHash}
                  className="btn-secondary text-xs py-1 px-3 whitespace-nowrap"
                >
                  {removingHash === seat.machineHash ? 'Removing…' : 'Remove'}
                </button>
              </li>
            ))}
          </ul>
        )}

        {removeError && <p className="mt-3 text-sm text-red-600">{removeError}</p>}

        <p className="mt-4 text-xs text-ink/50">
          Remove a machine to free up a seat — useful when you replace or sell a Mac.
        </p>
      </div>

      {/* Transfer email */}
      <div className="card">
        <button
          onClick={() => setShowTransfer((v) => !v)}
          className="flex items-center justify-between w-full text-left"
        >
          <h2 className="font-semibold">Transfer to a new email</h2>
          <span className="text-ink/40 text-sm">{showTransfer ? '▲' : '▼'}</span>
        </button>

        {showTransfer && (
          <form onSubmit={handleTransfer} className="mt-4 space-y-3">
            <p className="text-sm text-ink/60">
              Move your license to a new email address. Your machines and plan stay the same.
            </p>
            <div>
              <label className="block text-xs uppercase tracking-wide text-ink/60 mb-1">New email</label>
              <input
                type="email"
                required
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="new@example.com"
                className="input"
              />
            </div>
            <button type="submit" className="btn-primary" disabled={transferring}>
              {transferring ? 'Transferring…' : 'Transfer license'}
            </button>
            {transferError && <p className="text-sm text-red-600">{transferError}</p>}
          </form>
        )}
      </div>
    </div>
  );
}

// ─── Page ────────────────────────────────────────────────────────────────────

export default function AccountPage() {
  const [licenseKey, setLicenseKey] = useState<string | null>(null);
  const [email, setEmail] = useState<string | null>(null);
  const [info, setInfo] = useState<LicenseInfo | null>(null);

  function handleFound(key: string, em: string, data: LicenseInfo) {
    setLicenseKey(key);
    setEmail(em);
    setInfo(data);
  }

  async function handleRefresh() {
    if (!licenseKey || !email) return;
    const params = new URLSearchParams({ key: licenseKey, email });
    const res = await fetch(`/api/license/seats?${params}`);
    if (res.ok) {
      const data: LicenseInfo = await res.json();
      setInfo(data);
    }
  }

  function handleReset() {
    setLicenseKey(null);
    setEmail(null);
    setInfo(null);
  }

  return (
    <section className="pt-12 pb-20 max-w-xl">
      <h1 className="text-3xl font-semibold tracking-tight">Your license</h1>
      <p className="mt-3 text-ink/70">
        View your license status, manage activated machines, and transfer your license to a new email.
      </p>

      {!info || !licenseKey || !email ? (
        <LookupForm onFound={handleFound} />
      ) : (
        <Dashboard
          licenseKey={licenseKey}
          email={email}
          info={info}
          onRefresh={handleRefresh}
          onReset={handleReset}
        />
      )}

      <p className="mt-8 text-sm text-ink/50">
        Need to manage your subscription or invoices?{' '}
        <a href="/billing" className="underline hover:opacity-70">Open billing portal →</a>
      </p>
    </section>
  );
}
