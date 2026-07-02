'use client';

import { useState } from 'react';

export default function Admin() {
  const [token, setToken] = useState('');

  return (
    <section className="pt-12 pb-20 max-w-xl space-y-10">
      <div>
        <h1 className="text-3xl font-semibold tracking-tight">Admin dashboard</h1>
        <p className="mt-2 text-sm text-ink/60">
          Requires <code className="font-mono">ADMIN_TOKEN</code> env var on the server.
        </p>
      </div>

      <div className="card space-y-2">
        <label className="block text-xs uppercase tracking-wide text-ink/60">Admin token</label>
        <input
          type="password"
          value={token}
          onChange={(e) => setToken(e.target.value)}
          placeholder="paste token here — shared across all forms below"
          className="input w-full"
        />
      </div>

      <IssuePanel token={token} />
      <ResendLicensePanel token={token} />
      <ChangeEmailPanel token={token} />
      <LicensesByEmailPanel token={token} />
      <LookupPanel token={token} />
      <ActivationsPanel token={token} />
      <DeactivateAllPanel token={token} />
      <TransferPanel />
      <ResendPaymentFailedPanel token={token} />
      <RevokePanel token={token} />
      <ReactivatePanel token={token} />
      <ExtendPanel token={token} />
    </section>
  );
}

// ─── Issue comp / free license ────────────────────────────────────────────────

function IssuePanel({ token }: { token: string }) {
  const [email, setEmail] = useState('');
  const [plan, setPlan] = useState<'monthly' | 'yearly' | 'lifetime'>('lifetime');
  const [note, setNote] = useState('');
  const [result, setResult] = useState<{ key: string; email: string; plan: string; expiresAt: string | null } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function issue(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/issue', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, plan, note: note || undefined }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setEmail('');
        setNote('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Issue comp license</h2>
      <p className="text-sm text-ink/60 mb-3">
        Manually generate a license key for a user — no Stripe required. Use for speaker comps,
        beta testers, team members, or support resolutions.
      </p>
      <form onSubmit={issue} className="card space-y-3">
        <Field label="Email">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com"
            className="input"
            required
          />
        </Field>
        <Field label="Plan">
          <select
            value={plan}
            onChange={(e) => setPlan(e.target.value as typeof plan)}
            className="input"
          >
            <option value="lifetime">Lifetime</option>
            <option value="yearly">Yearly</option>
            <option value="monthly">Monthly</option>
          </select>
        </Field>
        <Field label="Note (optional — not stored, just echoed back)">
          <input
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="speaker comp, beta tester, …"
            className="input"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Issuing…' : 'Issue license'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 space-y-2 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">License issued ✓</p>
          <p className="text-xs text-ink/60">Send this key to the recipient:</p>
          <p className="font-mono text-base font-bold tracking-widest select-all">{result.key}</p>
          <p className="text-xs text-ink/50">
            {result.email} · {result.plan}
            {result.expiresAt ? ` · expires ${result.expiresAt.slice(0, 10)}` : ' · no expiry'}
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Resend license email ─────────────────────────────────────────────────────

function ResendLicensePanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [email, setEmail] = useState('');
  const [result, setResult] = useState<{ ok: true; to: string; key: string; plan: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function resend(e: React.FormEvent) {
    e.preventDefault();
    if (!key && !email) {
      setError('Enter a license key or an email address.');
      return;
    }
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const body: Record<string, string> = {};
      if (key) body.key = key.trim().toUpperCase();
      if (email) body.email = email.trim();
      const res = await fetch('/api/admin/resend-license', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const b = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${b.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
        setEmail('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Resend license email</h2>
      <p className="text-sm text-ink/60 mb-3">
        Re-send the license welcome email to a customer who lost their key. Provide a key{' '}
        <em>or</em> an email address. If only an email is given, the most recently issued active
        license for that address is used.
      </p>
      <form onSubmit={resend} className="card space-y-3">
        <Field label="License key (takes precedence if both are filled)">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX  (optional if email is set)"
            className="input font-mono"
          />
        </Field>
        <Field label="Customer email (used if no key is given)">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com  (optional if key is set)"
            className="input"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Sending…' : 'Resend license email'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Email sent ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            Sent to <strong>{result.to}</strong> — key{' '}
            <span className="font-mono select-all">{result.key}</span> ({result.plan})
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Admin email change ───────────────────────────────────────────────────────

function ChangeEmailPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [result, setResult] = useState<{ ok: true; key: string; oldEmail: string; newEmail: string; plan: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function changeEmail(e: React.FormEvent) {
    e.preventDefault();
    const k = key.trim().toUpperCase();
    if (!confirm(`Change email on ${k} to ${newEmail.trim()}? This takes effect immediately.`)) return;
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/change-email', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: k, newEmail: newEmail.trim() }),
      });
      if (!res.ok) {
        const b = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${b.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
        setNewEmail('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Change license email (admin)</h2>
      <p className="text-sm text-ink/60 mb-3">
        Update the email address on a license without requiring the customer&apos;s old email for
        auth. Use when a customer changed their primary email and can no longer use the self-service
        transfer flow. Verify identity out-of-band before using.
      </p>
      <form onSubmit={changeEmail} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="New email address">
          <input
            type="email"
            value={newEmail}
            onChange={(e) => setNewEmail(e.target.value)}
            placeholder="new@example.com"
            className="input"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-orange-600 text-white text-sm font-medium hover:bg-orange-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Updating…' : 'Change email'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Email updated ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            <span className="font-mono">{result.key}</span> ({result.plan}){' '}
            <span className="line-through text-ink/40">{result.oldEmail}</span>
            {' → '}
            <strong>{result.newEmail}</strong>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── License lookup ────────────────────────────────────────────────────────────

function LookupPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [email, setEmail] = useState('');
  const [result, setResult] = useState('');
  const [loading, setLoading] = useState(false);

  async function lookup(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult('');
    try {
      const params = new URLSearchParams({ key });
      if (email) params.set('email', email);
      const res = await fetch(`/api/admin/lookup?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setResult(`HTTP ${res.status}\n\n${await res.text()}`);
    } catch (err: any) {
      setResult(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">License lookup</h2>
      <form onSubmit={lookup} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="Email (optional — narrows the match)">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com"
            className="input"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Looking up…' : 'Look up'}
        </button>
      </form>
      {result && <pre className="card mt-3 font-mono text-xs whitespace-pre-wrap">{result}</pre>}
    </div>
  );
}

// ─── Activation management ────────────────────────────────────────────────────

type Activation = { machineHash: string; firstSeen: string; lastSeen: string };

function ActivationsPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [data, setData] = useState<{
    key: string; email: string; plan: string; status: string;
    seatCount: number; activations: Activation[];
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [removing, setRemoving] = useState<string | null>(null);

  async function fetchActivations(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    setData(null);
    try {
      const res = await fetch(`/api/admin/activations?key=${encodeURIComponent(key)}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setData(await res.json());
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  async function deactivate(machineHash: string) {
    setRemoving(machineHash);
    try {
      const params = new URLSearchParams({ key, machine: machineHash });
      const res = await fetch(`/api/admin/activations?${params}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        alert(`Failed: ${body.error ?? res.status}`);
      } else {
        // Refresh the list
        const refreshRes = await fetch(`/api/admin/activations?key=${encodeURIComponent(key)}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (refreshRes.ok) setData(await refreshRes.json());
      }
    } finally {
      setRemoving(null);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Machine activations</h2>
      <p className="text-sm text-ink/60 mb-3">
        List activated machines for a license, and free seats by deactivating old machines.
      </p>
      <form onSubmit={fetchActivations} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'List activations'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {data && (
        <div className="card mt-3 space-y-3">
          <div className="text-sm">
            <span className="font-mono font-semibold">{data.key}</span>
            {' · '}
            {data.email}
            {' · '}
            {data.plan}
            {' · '}
            <span className={data.status === 'active' ? 'text-green-600' : 'text-red-500'}>
              {data.status}
            </span>
            {' · '}
            {data.seatCount}/3 seats used
          </div>

          {data.activations.length === 0 ? (
            <p className="text-sm text-ink/50">No activations on record.</p>
          ) : (
            <table className="w-full text-xs font-mono">
              <thead>
                <tr className="text-left text-ink/50">
                  <th className="pb-1 pr-3">Machine hash</th>
                  <th className="pb-1 pr-3">First seen</th>
                  <th className="pb-1 pr-3">Last seen</th>
                  <th className="pb-1" />
                </tr>
              </thead>
              <tbody>
                {data.activations.map((a) => (
                  <tr key={a.machineHash} className="border-t border-ink/10">
                    <td className="py-1 pr-3 text-ink/70">{a.machineHash.slice(0, 16)}…</td>
                    <td className="py-1 pr-3 text-ink/50">{a.firstSeen.slice(0, 10)}</td>
                    <td className="py-1 pr-3 text-ink/50">{a.lastSeen.slice(0, 10)}</td>
                    <td className="py-1">
                      <button
                        onClick={() => deactivate(a.machineHash)}
                        disabled={removing === a.machineHash}
                        className="text-red-500 hover:underline disabled:opacity-40 text-xs"
                      >
                        {removing === a.machineHash ? 'Removing…' : 'Remove'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}

// ─── License revoke ────────────────────────────────────────────────────────────

function RevokePanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [result, setResult] = useState('');
  const [loading, setLoading] = useState(false);

  async function revoke(e: React.FormEvent) {
    e.preventDefault();
    if (!confirm(`Revoke license ${key}? This cannot be undone from this UI.`)) return;
    setLoading(true);
    setResult('');
    try {
      const res = await fetch('/api/admin/revoke', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key }),
      });
      setResult(`HTTP ${res.status}\n\n${await res.text()}`);
    } catch (err: any) {
      setResult(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Revoke license</h2>
      <p className="text-sm text-ink/60 mb-3">
        Sets license status to <code className="font-mono">canceled</code>. The next time the app
        validates, it will be rejected. Use for refunds or abuse cases.
      </p>
      <form onSubmit={revoke} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-red-600 text-white text-sm font-medium hover:bg-red-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Revoking…' : 'Revoke license'}
        </button>
      </form>
      {result && <pre className="card mt-3 font-mono text-xs whitespace-pre-wrap">{result}</pre>}
    </div>
  );
}

// ─── Reactivate license ───────────────────────────────────────────────────────

function ReactivatePanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [result, setResult] = useState<{ ok: boolean; key: string; previousStatus: string; newStatus: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function reactivate(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/reactivate', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Reactivate license</h2>
      <p className="text-sm text-ink/60 mb-3">
        Sets a canceled, expired, or past-due license back to{' '}
        <code className="font-mono">active</code>. Use for wrongly revoked licenses or
        manually resolved billing failures.
      </p>
      <form onSubmit={reactivate} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-green-600 text-white text-sm font-medium hover:bg-green-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Reactivating…' : 'Reactivate license'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-1">
          <p className="font-medium text-green-700">License reactivated</p>
          <p>
            Key: <code className="font-mono">{result.key}</code>
          </p>
          <p>
            Status:{' '}
            <span className="line-through text-ink/40">{result.previousStatus}</span>
            {' → '}
            <span className="font-semibold text-green-700">{result.newStatus}</span>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Extend license expiry ───────────────────────────────────────────────────

function ExtendPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [days, setDays] = useState('30');
  const [result, setResult] = useState<{
    ok: boolean;
    key: string;
    previousExpiresAt: string | null;
    newExpiresAt: string;
    days: number;
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function extend(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/extend', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key, days: Number(days) }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Extend license expiry</h2>
      <p className="text-sm text-ink/60 mb-3">
        Adds N days to a license's <code className="font-mono">expiresAt</code>. If the license has
        no expiry (lifetime) or is already expired, extends from today. Max 3650 days (10 years).
      </p>
      <form onSubmit={extend} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="Days to add">
          <input
            type="number"
            min={1}
            max={3650}
            value={days}
            onChange={(e) => setDays(e.target.value)}
            className="input"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Extending…' : 'Extend expiry'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-1">
          <p className="font-medium text-blue-700">Expiry extended by {result.days} days</p>
          <p>
            Key: <code className="font-mono">{result.key}</code>
          </p>
          <p>
            Previous:{' '}
            <span className="line-through text-ink/40">
              {result.previousExpiresAt ?? 'none (lifetime)'}
            </span>
          </p>
          <p>
            New expiry:{' '}
            <span className="font-semibold text-blue-700">{result.newExpiresAt}</span>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Licenses by email ────────────────────────────────────────────────────────

type LicenseRow = {
  key: string;
  email: string;
  plan: string;
  status: string;
  issuedAt: string;
  expiresAt: string | null;
  machineCount: number;
};

function LicensesByEmailPanel({ token }: { token: string }) {
  const [email, setEmail] = useState('');
  const [result, setResult] = useState<{ email: string; count: number; licenses: LicenseRow[] } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function lookup(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch(`/api/admin/licenses-by-email?email=${encodeURIComponent(email)}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Licenses by email</h2>
      <p className="text-sm text-ink/60 mb-3">
        Find all license keys associated with an email address. Useful for support — returns every
        license ever issued to that address, regardless of status.
      </p>
      <form onSubmit={lookup} className="card space-y-3">
        <Field label="Customer email">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com"
            className="input"
            required
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Searching…' : 'Find licenses'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 space-y-3">
          <p className="text-sm text-ink/60">
            {result.count === 0
              ? `No licenses found for ${result.email}.`
              : `${result.count} license${result.count === 1 ? '' : 's'} for ${result.email}`}
          </p>
          {result.licenses.length > 0 && (
            <table className="w-full text-xs font-mono">
              <thead>
                <tr className="text-left text-ink/50">
                  <th className="pb-1 pr-3">Key</th>
                  <th className="pb-1 pr-3">Plan</th>
                  <th className="pb-1 pr-3">Status</th>
                  <th className="pb-1 pr-3">Issued</th>
                  <th className="pb-1">Expires</th>
                </tr>
              </thead>
              <tbody>
                {result.licenses.map((lic) => (
                  <tr key={lic.key} className="border-t border-ink/10">
                    <td className="py-1 pr-3 select-all">{lic.key}</td>
                    <td className="py-1 pr-3 text-ink/70">{lic.plan}</td>
                    <td className={`py-1 pr-3 ${lic.status === 'active' ? 'text-green-600' : 'text-red-500'}`}>
                      {lic.status}
                    </td>
                    <td className="py-1 pr-3 text-ink/50">{lic.issuedAt.slice(0, 10)}</td>
                    <td className="py-1 text-ink/50">{lic.expiresAt ? lic.expiresAt.slice(0, 10) : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Resend payment-failed email ──────────────────────────────────────────────

function ResendPaymentFailedPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [force, setForce] = useState(false);
  const [result, setResult] = useState<{ ok: true; to: string; key: string; plan: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function resend(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/resend-payment-failed', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: key.trim().toUpperCase(), force }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
        setForce(false);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Resend payment-failed email</h2>
      <p className="text-sm text-ink/60 mb-3">
        Manually trigger the payment-failed email for a license key. By default only sends if the
        license is <code className="font-mono">past_due</code>; check <em>force</em> to override
        (useful for testing the email template).
      </p>
      <form onSubmit={resend} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
          <input
            type="checkbox"
            checked={force}
            onChange={(e) => setForce(e.target.checked)}
            className="rounded"
          />
          Force — send even if license is not <span className="font-mono ml-1">past_due</span>
        </label>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Sending…' : 'Resend email'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Email sent ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            Sent to <strong>{result.to}</strong> for key{' '}
            <span className="font-mono">{result.key}</span> ({result.plan})
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Deactivate all machines ──────────────────────────────────────────────────

function DeactivateAllPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [result, setResult] = useState<{ ok: true; key: string; removedCount: number } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function deactivateAll(e: React.FormEvent) {
    e.preventDefault();
    const k = key.trim().toUpperCase();
    if (!confirm(`Remove ALL activations for ${k}? The user will need to re-activate on each machine.`)) return;
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/deactivate-all', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: k }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Deactivate all machines</h2>
      <p className="text-sm text-ink/60 mb-3">
        Wipes every machine activation for a license in one shot. Use when a customer has lost
        access to all their machines and can&apos;t deactivate them individually.
      </p>
      <form onSubmit={deactivateAll} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-orange-600 text-white text-sm font-medium hover:bg-orange-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Deactivating…' : 'Deactivate all'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Done ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            Removed <strong>{result.removedCount}</strong> activation
            {result.removedCount === 1 ? '' : 's'} for{' '}
            <span className="font-mono">{result.key}</span>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── License transfer (support) ───────────────────────────────────────────────

function TransferPanel() {
  const [key, setKey] = useState('');
  const [email, setEmail] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [result, setResult] = useState<{ ok: true; key: string; email: string; plan: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function transfer(e: React.FormEvent) {
    e.preventDefault();
    if (!confirm(`Transfer ${key} from ${email} → ${newEmail}?`)) return;
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/license/transfer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: key.trim().toUpperCase(), email: email.trim(), newEmail: newEmail.trim() }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
        setEmail('');
        setNewEmail('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Transfer license</h2>
      <p className="text-sm text-ink/60 mb-3">
        Move a license to a different email address. Requires the current key + email for auth
        (collect from the customer). Use for email changes or account consolidation.
      </p>
      <form onSubmit={transfer} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="Current email (for verification)">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="current@example.com"
            className="input"
            required
          />
        </Field>
        <Field label="New email">
          <input
            type="email"
            value={newEmail}
            onChange={(e) => setNewEmail(e.target.value)}
            placeholder="new@example.com"
            className="input"
            required
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Transferring…' : 'Transfer license'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Transferred ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            <span className="font-mono">{result.key}</span> ({result.plan}) is now registered to{' '}
            <strong>{result.email}</strong>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Shared ────────────────────────────────────────────────────────────────────

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="text-xs uppercase tracking-wide text-ink/60">{label}</span>
      <div className="mt-1">{children}</div>
    </label>
  );
}
