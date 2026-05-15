const TRADING_DAYS = 252

export function computeReturns(prices) {
  if (prices.length < 2) return { logReturns: [], mean: 0, variance: 0, annVol: 0, annDrift: 0 }
  const logReturns = []
  for (let i = 1; i < prices.length; i++) {
    if (prices[i - 1] > 0 && prices[i] > 0) logReturns.push(Math.log(prices[i] / prices[i - 1]))
  }
  const n = logReturns.length
  const mean = logReturns.reduce((s, r) => s + r, 0) / n
  const variance = logReturns.reduce((s, r) => s + (r - mean) ** 2, 0) / (n - 1)
  const dailyStd = Math.sqrt(variance)
  const annVol = dailyStd * Math.sqrt(TRADING_DAYS)
  // GBM drift: annualised (μ - σ²/2)
  const annDrift = mean * TRADING_DAYS - 0.5 * annVol ** 2
  return { logReturns, mean, variance, annVol, annDrift }
}

export { TRADING_DAYS }
