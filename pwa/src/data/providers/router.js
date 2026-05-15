import { yahooProvider } from './yahoo.js'
import { alphaVantageProvider } from './alphaVantage.js'

const providers = [yahooProvider, alphaVantageProvider]

async function withFailover(fn) {
  let lastErr
  for (const provider of providers) {
    try {
      return await fn(provider)
    } catch (err) {
      console.warn(`${provider.name} failed:`, err.message)
      lastErr = err
    }
  }
  throw lastErr
}

export const router = {
  search: q => withFailover(p => p.search(q)),
  fetchHistory: (symbol, from, to, interval) => withFailover(p => p.fetchHistory(symbol, from, to, interval)),
  fetchQuote: symbol => withFailover(p => p.fetchQuote(symbol)),
}
