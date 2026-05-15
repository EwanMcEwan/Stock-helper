import { TRADING_DAYS } from './returns.js'

// GARCH(1,1) with moment-matching parameter estimation
export function garchForecast(logReturns, horizonDays) {
  if (logReturns.length < 30) return null
  const n = logReturns.length
  const mean = logReturns.reduce((s, r) => s + r, 0) / n
  const uncondVar = logReturns.reduce((s, r) => s + (r - mean) ** 2, 0) / (n - 1)

  // Standard GARCH(1,1) moment-matching defaults
  const alpha = 0.10, beta = 0.85
  const omega = uncondVar * (1 - alpha - beta)

  const lastR = logReturns[logReturns.length - 1]
  let h = omega + alpha * lastR ** 2 + beta * uncondVar

  let sumVar = 0
  for (let d = 0; d < horizonDays; d++) {
    h = omega + (alpha + beta) * h
    sumVar += h
  }

  const avgDailyVar = sumVar / horizonDays
  return Math.sqrt(avgDailyVar * TRADING_DAYS)
}
