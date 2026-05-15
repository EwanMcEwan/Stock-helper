// Yahoo Finance via a CORS proxy (no API key required)
// corsproxy.io is a free public proxy — fine for personal use

function proxyUrl(url) {
  const proxy = localStorage.getItem('sh:corsProxy') || 'https://corsproxy.io/?'
  return `${proxy}${encodeURIComponent(url)}`
}

async function yfetch(url) {
  const res = await fetch(proxyUrl(url), {
    headers: { 'User-Agent': 'Mozilla/5.0' },
  })
  if (res.status === 429) throw Object.assign(new Error('Rate limited'), { code: 429 })
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

export const yahooProvider = {
  name: 'Yahoo Finance',

  async search(query) {
    const url = `https://query1.finance.yahoo.com/v1/finance/search?q=${encodeURIComponent(query)}&quotesCount=20&newsCount=0`
    const data = await yfetch(url)
    return (data.quotes || []).map(q => ({
      id: q.symbol,
      name: q.longname || q.shortname || q.symbol,
      exchange: q.exchDisp || '',
      kind: kindFrom(q.typeDisp),
      currency: q.currency || 'USD',
    })).filter(a => a.id)
  },

  async fetchHistory(symbol, fromTs, toTs, interval = '1d') {
    const url = `https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?period1=${fromTs}&period2=${toTs}&interval=${interval}&events=div,splits`
    const data = await yfetch(url)
    return parseChart(data)
  },

  async fetchQuote(symbol) {
    const url = `https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?range=1d&interval=1m`
    const data = await yfetch(url)
    const meta = data?.chart?.result?.[0]?.meta || {}
    const price = meta.regularMarketPrice || 0
    const prev = meta.chartPreviousClose || price
    return { symbol, price, change: price - prev, changePercent: prev ? ((price - prev) / prev) * 100 : 0 }
  },
}

function parseChart(data) {
  const result = data?.chart?.result?.[0]
  if (!result) return []
  const ts = result.timestamp || []
  const q = result.indicators?.quote?.[0] || {}
  const adj = result.indicators?.adjclose?.[0]?.adjclose || []
  return ts.map((t, i) => {
    const o = q.open?.[i], h = q.high?.[i], l = q.low?.[i], c = q.close?.[i]
    if (o == null || h == null || l == null || c == null) return null
    return { date: t * 1000, open: o, high: h, low: l, close: c, volume: q.volume?.[i] || 0, adjClose: adj[i] ?? c }
  }).filter(Boolean)
}

function kindFrom(type = '') {
  const t = type.toLowerCase()
  if (t === 'etf') return 'ETF'
  if (t === 'etn') return 'ETN'
  return 'Stock'
}
