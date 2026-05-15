// All technical indicators — pure functions, no dependencies

// SMA: simple moving average
export function sma(values, period) {
  const out = new Array(values.length).fill(NaN)
  if (values.length < period) return out
  let sum = values.slice(0, period).reduce((a, b) => a + b, 0)
  out[period - 1] = sum / period
  for (let i = period; i < values.length; i++) {
    sum += values[i] - values[i - period]
    out[i] = sum / period
  }
  return out
}

// EMA: exponential moving average (k = 2/(period+1))
export function ema(values, period) {
  const out = new Array(values.length).fill(NaN)
  if (values.length < period) return out
  const k = 2 / (period + 1)
  out[period - 1] = values.slice(0, period).reduce((a, b) => a + b, 0) / period
  for (let i = period; i < values.length; i++) {
    out[i] = values[i] * k + out[i - 1] * (1 - k)
  }
  return out
}

// RSI: Wilder's method
export function rsi(values, period = 14) {
  const out = new Array(values.length).fill(NaN)
  if (values.length <= period) return out
  let avgGain = 0, avgLoss = 0
  for (let i = 1; i <= period; i++) {
    const d = values[i] - values[i - 1]
    if (d > 0) avgGain += d; else avgLoss -= d
  }
  avgGain /= period; avgLoss /= period
  out[period] = avgLoss === 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss)
  for (let i = period + 1; i < values.length; i++) {
    const d = values[i] - values[i - 1]
    avgGain = (avgGain * (period - 1) + Math.max(d, 0)) / period
    avgLoss = (avgLoss * (period - 1) + Math.max(-d, 0)) / period
    out[i] = avgLoss === 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss)
  }
  return out
}

// MACD: EMA(fast) - EMA(slow), signal = EMA(9) of MACD
export function macd(values, fast = 12, slow = 26, signal = 9) {
  const e12 = ema(values, fast)
  const e26 = ema(values, slow)
  const macdLine = values.map((_, i) =>
    isNaN(e12[i]) || isNaN(e26[i]) ? NaN : e12[i] - e26[i]
  )
  // Compute signal EMA only over valid range
  const validIdx = macdLine.map((v, i) => !isNaN(v) ? i : -1).filter(i => i >= 0)
  const signalLine = new Array(values.length).fill(NaN)
  if (validIdx.length >= signal) {
    const validMacd = validIdx.map(i => macdLine[i])
    const sigEma = ema(validMacd, signal)
    validIdx.forEach((origIdx, j) => { signalLine[origIdx] = sigEma[j] })
  }
  const histogram = macdLine.map((m, i) =>
    isNaN(m) || isNaN(signalLine[i]) ? NaN : m - signalLine[i]
  )
  return { macdLine, signalLine, histogram }
}

// Bollinger Bands
export function bollingerBands(values, period = 20, mult = 2) {
  const middle = sma(values, period)
  const upper = new Array(values.length).fill(NaN)
  const lower = new Array(values.length).fill(NaN)
  const pctB  = new Array(values.length).fill(NaN)
  for (let i = period - 1; i < values.length; i++) {
    const window = values.slice(i - period + 1, i + 1)
    const mean = middle[i]
    const std = Math.sqrt(window.reduce((s, v) => s + (v - mean) ** 2, 0) / period)
    upper[i] = mean + mult * std
    lower[i] = mean - mult * std
    const w = upper[i] - lower[i]
    pctB[i] = w === 0 ? 0.5 : (values[i] - lower[i]) / w
  }
  return { upper, middle, lower, pctB }
}

// Compute all indicators at once
export function computeAll(closes) {
  return {
    sma20:  sma(closes, 20),
    sma50:  sma(closes, 50),
    sma200: sma(closes, 200),
    rsi14:  rsi(closes, 14),
    macd:   macd(closes),
    bb:     bollingerBands(closes, 20, 2),
  }
}

// Derive human-readable signals from indicator values
export function deriveSignals(closes, indicators) {
  const last = closes.length - 1
  const signals = []
  const r = indicators.rsi14[last]
  if (!isNaN(r)) signals.push({
    name: 'RSI(14)', value: r.toFixed(1),
    direction: r < 30 ? 'bull' : r > 70 ? 'bear' : 'neutral',
    label: r < 30 ? 'Oversold' : r > 70 ? 'Overbought' : 'Neutral',
  })
  const h = indicators.macd.histogram[last]
  if (!isNaN(h)) signals.push({
    name: 'MACD', value: h.toFixed(4),
    direction: h > 0 ? 'bull' : h < 0 ? 'bear' : 'neutral',
    label: h > 0 ? 'Positive momentum' : 'Negative momentum',
  })
  const pb = indicators.bb.pctB[last]
  if (!isNaN(pb)) signals.push({
    name: 'Bollinger %B', value: pb.toFixed(2),
    direction: pb > 1 ? 'bear' : pb < 0 ? 'bull' : 'neutral',
    label: pb > 1 ? 'Above upper band' : pb < 0 ? 'Below lower band' : 'Within bands',
  })
  const s20 = indicators.sma20[last], s50 = indicators.sma50[last], c = closes[last]
  if (!isNaN(s20) && !isNaN(s50)) signals.push({
    name: 'SMA Trend', value: (c - s50).toFixed(2),
    direction: s20 > s50 && c > s20 ? 'bull' : s20 < s50 && c < s20 ? 'bear' : 'neutral',
    label: s20 > s50 ? 'SMA20 above SMA50 (uptrend)' : 'SMA20 below SMA50 (downtrend)',
  })
  return signals
}
