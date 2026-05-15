import { TRADING_DAYS } from './returns.js'

export function historicalVaR(logReturns, confidence = 0.95) {
  if (!logReturns.length) return 0
  const sorted = [...logReturns].sort((a, b) => a - b)
  const idx = Math.floor((1 - confidence) * sorted.length)
  return 1 - Math.exp(sorted[Math.max(idx, 0)])
}

export function sharpeRatio(logReturns, riskFreeRate = 0.05) {
  if (logReturns.length < 2) return 0
  const n = logReturns.length
  const mean = logReturns.reduce((s, r) => s + r, 0) / n
  const variance = logReturns.reduce((s, r) => s + (r - mean) ** 2, 0) / (n - 1)
  const std = Math.sqrt(variance)
  if (std === 0) return 0
  const dailyRF = riskFreeRate / TRADING_DAYS
  return ((mean - dailyRF) / std) * Math.sqrt(TRADING_DAYS)
}

export function maxDrawdown(prices) {
  if (prices.length < 2) return { drawdown: 0, label: '0.0%' }
  let peak = prices[0], maxDD = 0
  for (const p of prices) {
    if (p > peak) peak = p
    const dd = (p - peak) / peak
    if (dd < maxDD) maxDD = dd
  }
  return { drawdown: maxDD, label: `${(maxDD * 100).toFixed(1)}%` }
}
