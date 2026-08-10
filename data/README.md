# data/

Snapshots written by `.github/workflows/refresh-data.yml` (which runs
`scripts/fetch-data.mjs`). Do not edit by hand — the workflow overwrites them.

| File | Source | Why it is a snapshot |
|---|---|---|
| `macro.json` | FRED (St. Louis Fed) | `api.stlouisfed.org` sends no `Access-Control-Allow-Origin` header, so browsers block direct calls |
| `reddit.json` | Reddit hot posts | Reddit refuses unauthenticated cross-origin reads of its `.json` endpoints |

The app fetches these same-origin, so no CORS applies and your FRED key never
reaches the browser. Until the workflow has run once, these files do not exist
and the app falls back to trying the APIs directly (which normally fails —
the Data health panel will say so).
