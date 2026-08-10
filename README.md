# Stock-helper — Market Watch

A single-page market dashboard: live quotes, a sector heat map, market news,
an earnings calendar with pre-market / after-hours timing, macro indicators,
Reddit chatter, Polymarket odds, and a per-ticker research panel.

Runs entirely in the browser. Only two API keys, both free:

- **Finnhub** — quotes, news, earnings calendar, company data ([sign up](https://finnhub.io/register))
- **FRED** — macro series ([sign up](https://fredaccount.stlouisfed.org/apikeys))

---

## Why it stopped working

Four separate things, all of which are now fixed or surfaced:

1. **FRED can't be called from a browser.** `api.stlouisfed.org` returns no
   `Access-Control-Allow-Origin` header, so the macro cards were blocked by
   CORS regardless of the key. Fixed by fetching FRED in GitHub Actions and
   serving `data/macro.json` same-origin.

2. **Reddit blocks unauthenticated cross-origin `.json` reads.** Same fix —
   the Action writes `data/reddit.json`.

3. **Finnhub's free tier no longer includes `/stock/candle`.** It returns
   `403`, which silently removed the price chart and the 50-day moving average
   from the research panel. The panel now says this plainly instead of
   rendering nothing. Everything else on that panel is free-tier data.

4. **The app was firing 40+ Finnhub requests simultaneously.** Indexes +
   heat map + watchlists went out in one `Promise.all`, blowing past the free
   tier's burst limit (30 calls/sec, 60/min) and getting `429`s back. All
   Finnhub traffic now goes through a queue — 5 concurrent, 55 per rolling
   minute — with a per-symbol cache so a refresh doesn't re-spend the budget.

Underlying all of it: **every failure was swallowed** into a `console.warn`,
so a broken source just rendered a blank panel. Every fetcher now reports into
a **Data health** panel (gear icon → Data health), empty panels state their own
reason, and a banner appears on the Overview tab when a source is down.

---

## Setup

### 1. Add your keys

Open the app, tap the gear icon, paste your Finnhub key. Keys live in
`localStorage` on your device and are sent only to the API provider.

### 2. Publish it (recommended)

The macro and Reddit panels need the snapshot files, which means serving the
app over HTTP rather than opening the file directly.

1. **Settings → Secrets and variables → Actions → New repository secret**
   Name `FRED_API_KEY`, value = your FRED key.
2. **Settings → Pages →** Source: *Deploy from a branch*, Branch: `main`, folder `/ (root)`.
3. **Actions → Refresh market data snapshots → Run workflow** to build the
   first snapshot (afterwards it runs every 30 minutes on its own).

Your app is then at `https://<username>.github.io/Stock-helper/`.

> The repo is public, so keep the FRED key in Actions secrets — never commit it.
> The snapshot files contain only public data, no key.

### 3. Running it locally instead

`index.html` opens straight from disk and quotes, news, earnings, research and
Polymarket all work. Macro and Reddit will not, because the snapshots aren't
being served. To get everything locally:

```bash
FRED_API_KEY=your_key node scripts/fetch-data.mjs   # build the snapshots
python3 -m http.server 8000                          # serve over HTTP
```

Then open <http://localhost:8000>.

There is also a **CORS relay** field in settings as a last resort — it routes
only the blocked sources through a public relay. It's off by default, and note
that the relay would see your FRED key in the request URL, so the snapshot
route is the better one.

---

## Earnings timing

The calendar tags every report using Finnhub's `hour` field, sorted in the
order the trading day runs:

| Tag | Meaning |
|---|---|
| **Pre-Market** | `bmo` — before the open |
| **Mid-Day** | `dmh` — during market hours |
| **After-Hours** | `amc` — after the close |
| **Time TBD** | not yet scheduled by the company |

Today is highlighted, the **Watchlist** / **All** toggle filters to symbols you
track, and once a company reports, the actual EPS is shown against the estimate
and coloured by beat/miss.

---

## A note on the Finnhub free tier

Quotes, market news, company news, company profile, analyst recommendations and
basic financials are all free. Historical candles are not. If Finnhub also
moves the earnings calendar behind a plan, the Data health panel will report
`403 — this endpoint is premium-only` rather than showing an empty calendar.

## Disclaimer

Data and descriptive statistics only. No price predictions, no recommendations,
no investment advice. Verify everything independently before acting.
