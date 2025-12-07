Webapp (Next.js)

This is a minimal Next.js full-stack app to run a small set of predefined SQL queries
against your project's Postgres database.

Quick start

1. Copy `.env.example` to `.env.local` and set Postgres connection values (or set environment variables):

   - `PGHOST` (e.g. `localhost`)
   - `PGPORT` (e.g. `5432`)
   - `PGUSER`
   - `PGPASSWORD`
   - `PGDATABASE` (e.g. `movies_db`)

2. Install dependencies and run dev server:

```powershell
cd webapp-nextjs
npm install
npm run dev
```

3. Open `http://localhost:3001` and choose a query to run.

Security notes

- The API only allows running predefined queries (no raw SQL from clients).
- Do not expose this app to the public without proper authentication.
- Always backup your DB before running any destructive queries.
