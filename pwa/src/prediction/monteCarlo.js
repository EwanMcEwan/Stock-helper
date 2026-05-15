import { TRADING_DAYS } from './returns.js'

// Box-Muller transform for standard normal samples
function randNormal() {
  let u, v
  do { u = Math.random() } while (u === 0)
  v = Math.random()
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v)
}

export function simulate({ startPrice, drift, volatility, days, simulations = 2000 }) {
  const dt = 1 / TRADING_DAYS
  const sqrtDt = Math.sqrt(dt)
  const driftDt = (drift - 0.5 * volatility ** 2) * dt

  const paths = Array.from({ length: simulations }, () => {
    const path = new Float64Array(days + 1)
    path[0] = startPrice
    for (let d = 1; d <= days; d++) {
      path[d] = path[d - 1] * Math.exp(driftDt + volatility * sqrtDt * randNormal())
    }
    return path
  })

  // Compute percentile bands day by day
  const p5 = [], p25 = [], p50 = [], p75 = [], p95 = []
  for (let d = 0; d <= days; d++) {
    const prices = paths.map(p => p[d]).sort((a, b) => a - b)
    const n = prices.length
    p5.push(prices[Math.floor(n * 0.05)])
    p25.push(prices[Math.floor(n * 0.25)])
    p50.push(prices[Math.floor(n * 0.50)])
    p75.push(prices[Math.floor(n * 0.75)])
    p95.push(prices[Math.floor(n * 0.95)])
  }

  return { paths, bands: { p5, p25, p50, p75, p95 } }
}

export function computeProbabilities(paths, startPrice, thresholds) {
  const endPrices = paths.map(p => p[p.length - 1])
  return thresholds.map(t => {
    const count = t >= 0
      ? endPrices.filter(p => (p - startPrice) / startPrice >= t).length
      : endPrices.filter(p => (p - startPrice) / startPrice <= t).length
    const label = t >= 0
      ? `Rises ≥ ${(t * 100).toFixed(0)}%`
      : `Falls ≥ ${(Math.abs(t) * 100).toFixed(0)}%`
    return { label, probability: count / endPrices.length }
  })
}
