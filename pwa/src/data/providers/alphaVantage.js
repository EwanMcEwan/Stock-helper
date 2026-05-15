// Alpha Vantage — CORS-friendly, free tier: 25 req/day
// Users add their own key in Settings

const BASE = 'https://www.alphavantage.co/query'

function getKey() {
  return localStorage.getItem('sh:avKey') || ''
}

async function avFetch(params) {
  const key = getKey()
  if (!key) throw new Error('No Alpha Vantage API key set')
  const url = `${BASE}?${new URLSearchParams({ ...params, apikey: key })}`
  const res = await fetch(url)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  const data = await res.json()
  if (data.Note || data.Information) throw Object.assign(new Error('Rate limited'), { code: 429 })
  return data
}

export const alphaVantageProvider = {
  name: 'Alpha Vantage',

  async search(query) {
    const data = await avFetch({ function: 'SYMBOL_SEARCH', keywords: query })
    return (data.bestMatches || []).map(m => ({
      id: m['1. symbol'],
      name: m['2. name'],
      exchange: m['4. region'],
      kind: 'Stock',
      currency: m['8. currency'] || 'USD',
    }))
  },

  async fetchHistory(symbol, fromTs, toTs) {
    const data = await avFetch({ function: 'TIME_SERIES_DAILY_ADJUSTED', symbol, outputsize: 'full' })
    const series = data['Time Series (Daily)'] || {}
    return Object.entries(series)
      .map(([date, v]) => {
        const ts = new Date(date).getTime()
        if (ts < fromTs || ts > toTs) return null
        return {
          date: ts,
          open: +v['1. open'], high: +v['2. high'], low: +v['3. low'],
          close: +v['4. close'], volume: +v['6. volume'],
          adjClose: +v['5. adjusted close'],
        }
      })
      .filter(Boolean)
      .sort((a, b) => a.date - b.date)
  },

  async fetchQuote(symbol) {
    const data = await avFetch({ function: 'GLOBAL_QUOTE', symbol })
    const q = data['Global Quote'] || {}
    const price = +q['05. price'] || 0
    const change = +q['09. change'] || 0
    const changePercent = parseFloat(q['10. change percent']) || 0
    return { symbol, price, change, changePercent }
  },
}
