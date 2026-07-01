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

      <LookupPanel token={token} />
      <ActivationsPanel token={token} />
      <RevokePanel token={token} />
    </section>
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

// ─── Shared ────────────────────────────────────────────────────────────────────

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="text-xs uppercase tracking-wide text-ink/60">{label}</span>
      <div className="mt-1">{children}</div>
    </label>
  );
}
