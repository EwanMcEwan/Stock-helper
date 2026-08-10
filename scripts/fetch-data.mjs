#!/usr/bin/env node
/**
 * Builds the same-origin data snapshots the app reads from `data/`.
 *
 * Why this exists: two of the app's sources cannot be called from a browser.
 *
 *   - api.stlouisfed.org (FRED) sends no Access-Control-Allow-Origin header,
 *     so a browser fetch is blocked by CORS no matter how valid the key is.
 *   - reddit.com refuses unauthenticated cross-origin reads of its .json
 *     endpoints.
 *
 * Both are fine to call from a server, so this script runs in GitHub Actions
 * and commits the results. The page then loads `data/macro.json` and
 * `data/reddit.json` same-origin, with no key in the browser at all.
 *
 * Run locally with:  FRED_API_KEY=xxxx node scripts/fetch-data.mjs
 */

import { writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DATA_DIR = join(ROOT, "data");

/* Keep this list in sync with FRED_SERIES in index.html. */
const FRED_SERIES = ["DGS10", "DFF", "VIXCLS", "DCOILWTICO", "UNRATE", "T10Y2Y"];

/* Keep in sync with DEFAULTS.SUBREDDITS in index.html. */
const SUBREDDITS = [
  "wallstreetbets", "stocks", "investing", "StockMarket", "options",
  "Economics", "SecurityAnalysis", "geopolitics", "worldnews",
];

const UA = "Stock-helper/1.0 (https://github.com/EwanMcEwan/Stock-helper)";

async function getJson(url, headers = {}) {
  const r = await fetch(url, { headers: { "User-Agent": UA, ...headers } });
  if (!r.ok) throw new Error(`HTTP ${r.status} ${r.statusText}`);
  return r.json();
}

/* Retry transient failures; a rate-limited run should not blank the snapshot. */
async function withRetry(label, fn, attempts = 3) {
  let lastError;
  for (let i = 0; i < attempts; i++) {
    try { return await fn(); }
    catch (e) {
      lastError = e;
      if (i < attempts - 1) {
        const wait = 2000 * Math.pow(2, i);
        console.warn(`  ${label}: ${e.message} — retrying in ${wait}ms`);
        await new Promise(res => setTimeout(res, wait));
      }
    }
  }
  throw lastError;
}

async function buildMacro() {
  const key = process.env.FRED_API_KEY;
  if (!key) {
    console.error("FRED_API_KEY is not set — skipping macro.json");
    return { skipped: true };
  }

  const series = {};
  let ok = 0;
  for (const id of FRED_SERIES) {
    const url = `https://api.stlouisfed.org/fred/series/observations` +
      `?series_id=${id}&api_key=${encodeURIComponent(key)}` +
      `&file_type=json&sort_order=desc&limit=60`;
    try {
      const d = await withRetry(id, () => getJson(url));
      series[id] = (d.observations || [])
        .filter(o => o.value !== ".")
        .reverse()
        .map(o => ({ date: o.date, value: parseFloat(o.value) }));
      ok++;
      console.log(`  ${id}: ${series[id].length} observations`);
    } catch (e) {
      // Never let one bad series abort the whole snapshot.
      series[id] = null;
      console.error(`  ${id}: FAILED — ${e.message}`);
    }
  }

  if (!ok) throw new Error("every FRED series failed — check FRED_API_KEY");

  await writeFile(
    join(DATA_DIR, "macro.json"),
    JSON.stringify({ generated: new Date().toISOString(), series }, null, 1)
  );
  console.log(`macro.json written (${ok}/${FRED_SERIES.length} series)`);
  return { ok };
}

async function buildReddit() {
  const posts = [];
  let ok = 0;
  for (const sub of SUBREDDITS) {
    const url = `https://www.reddit.com/r/${encodeURIComponent(sub)}/hot.json?limit=8&raw_json=1`;
    try {
      const d = await withRetry(sub, () => getJson(url));
      for (const child of (d?.data?.children || [])) {
        const p = child.data;
        if (p.stickied) continue;
        posts.push({
          sub,
          title: p.title,
          url: "https://reddit.com" + p.permalink,
          ext: p.url,
          score: p.score,
          comments: p.num_comments,
          author: p.author,
          created: p.created_utc,
          flair: p.link_flair_text || "",
        });
      }
      ok++;
      console.log(`  r/${sub}: ok`);
    } catch (e) {
      console.error(`  r/${sub}: FAILED — ${e.message}`);
    }
    // Be a good citizen with Reddit's unauthenticated endpoint.
    await new Promise(res => setTimeout(res, 1200));
  }

  if (!ok) throw new Error("every subreddit failed");

  posts.sort((a, b) => b.created - a.created);
  await writeFile(
    join(DATA_DIR, "reddit.json"),
    JSON.stringify({ generated: new Date().toISOString(), posts: posts.slice(0, 60) }, null, 1)
  );
  console.log(`reddit.json written (${posts.length} posts from ${ok}/${SUBREDDITS.length} subreddits)`);
  return { ok };
}

await mkdir(DATA_DIR, { recursive: true });

let failures = 0;

console.log("FRED:");
try { await buildMacro(); } catch (e) { failures++; console.error("macro.json FAILED — " + e.message); }

console.log("Reddit:");
try { await buildReddit(); } catch (e) { failures++; console.error("reddit.json FAILED — " + e.message); }

// Exit non-zero only if *both* halves failed; a partial snapshot still beats none.
if (failures >= 2) {
  console.error("Both snapshots failed.");
  process.exit(1);
}
console.log("Done.");
