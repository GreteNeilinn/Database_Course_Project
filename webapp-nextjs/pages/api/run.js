import { Pool } from 'pg';
import queries from '../../lib/queries';

// Default (hardcoded) DB credentials from project README. These can still be
// overridden by environment variables when present (e.g. .env.local or process env).
const DEFAULT_DB = {
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT ? parseInt(process.env.PGPORT, 10) : 5432,
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || 'mysecretpassword',
  database: process.env.PGDATABASE || 'movies_db',
  max: 5
};

// create a global pool to reuse connections in dev/hot-reload
let pool;
if (!global._pgPool) {
  global._pgPool = new Pool(DEFAULT_DB);
}
pool = global._pgPool;

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Only POST allowed' });

  const { key } = req.body || {};
  if (!key || typeof key !== 'string' || !queries[key]) {
    return res.status(400).json({ error: 'Invalid or missing query key' });
  }

  const entry = queries[key];
  const sql = entry.sql;

  // Build parameter array if this query declares params
  let paramsArray = [];
  if (Array.isArray(entry.params) && entry.params.length > 0) {
    const provided = req.body.params || {};
    for (let i = 0; i < entry.params.length; i++) {
      const p = entry.params[i];
      if (provided[p.name] === undefined || provided[p.name] === null || String(provided[p.name]).trim() === '') {
        return res.status(400).json({ error: 'Missing parameter', param: p.name });
      }
      // Basic type coercion for common types
      let val = provided[p.name];
      if (p.type === 'int') val = parseInt(val, 10);
      paramsArray.push(val);
    }
  }

  try {
    const start = Date.now();
    const result = await pool.query(sql, paramsArray.length ? paramsArray : undefined);
    const duration = Date.now() - start;
    return res.status(200).json({ rows: result.rows, rowCount: result.rowCount, durationMs: duration });
  } catch (err) {
    console.error('Query error', err);
    return res.status(500).json({ error: 'Query failed', detail: err.message });
  }
}
