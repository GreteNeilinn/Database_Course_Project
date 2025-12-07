import { useState } from 'react';
import queries from '../lib/queries';

export default function Home() {
  const [key, setKey] = useState(Object.keys(queries)[0]);
  const [loading, setLoading] = useState(false);
  const [rows, setRows] = useState([]);
  const [error, setError] = useState(null);
  const [params, setParams] = useState({});

  async function runQuery() {
    setLoading(true);
    setError(null);
    setRows([]);
    try {
      const payload = { key };
      // include params if present
      if (Object.keys(params).length) payload.params = params;

      const res = await fetch('/api/run', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      if (!res.ok) throw new Error(body.error || body.detail || 'Unknown error');
      if (!res.ok) throw new Error(data.error || data.detail || 'Unknown error');
      setRows(data.rows || []);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  const cols = rows.length ? Object.keys(rows[0]) : [];

  return (
    <div style={{ padding: 24, fontFamily: 'Arial, sans-serif' }}>
      <h1>Database Query Runner</h1>
      <p>Select a predefined query and click Run.</p>

      <div style={{ marginBottom: 12 }}>
        <select value={key} onChange={(e) => setKey(e.target.value)}>
          {Object.entries(queries).map(([k, v]) => (
            <option key={k} value={k}>{v.label}</option>
          ))}
        </select>
        {queries[key] && Array.isArray(queries[key].params) && (
          <span style={{ marginLeft: 8 }}>
            {queries[key].params.map((p) => (
              <input
                key={p.name}
                placeholder={p.placeholder || p.name}
                style={{ marginLeft: 6 }}
                value={params[p.name] ?? ''}
                onChange={(e) => setParams({ ...params, [p.name]: e.target.value })}
              />
            ))}
          </span>
        )}
        <button style={{ marginLeft: 8 }} onClick={runQuery} disabled={loading}>
          {loading ? 'Running...' : 'Run'}
        </button>
      </div>

      {error && <div style={{ color: 'crimson' }}>Error: {error}</div>}

      {rows.length > 0 && (
        <div style={{ maxHeight: '60vh', overflow: 'auto' }}>
          <table border="1" cellPadding="6" style={{ borderCollapse: 'collapse' }}>
            <thead>
              <tr>{cols.map((c) => <th key={c}>{c}</th>)}</tr>
            </thead>
            <tbody>
              {rows.map((r, i) => (
                <tr key={i}>{cols.map((c) => <td key={c}>{String(r[c] ?? '')}</td>)}</tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {rows.length === 0 && !loading && <div>No results yet.</div>}
    </div>
  );
}
