import { useState, useEffect, useCallback } from 'react'
import { router } from '../data/providers/router.js'
import { cacheGet, cacheSet } from '../data/cache.js'
import { computeAll, deriveSignals } from '../prediction/indicators.js'

const RANGES = {
  '1M': 30, '3M': 90, '6M': 180, '1Y': 365, '2Y': 730, '5Y': 1825,
}

export { RANGES }

export function useAssetDetail(asset) {
  const [bars, setBars] = useState([])
  const [indicators, setIndicators] = useState(null)
  const [signals, setSignals] = useState([])
  const [quote, setQuote] = useState(null)
  const [range, setRange] = useState('6M')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const load = useCallback(async (r) => {
    if (!asset) return
    setLoading(true); setError(null)
    try {
      const days = RANGES[r]
      const toTs = Math.floor(Date.now() / 1000)
      // Buffer for weekends/holidays
      const fromTs = Math.floor((Date.now() - days * 1.5 * 86400_000) / 1000)

      const cacheKey = `${asset.id}:${r}`
      const cached = cacheGet('eod', cacheKey)
      let data = cached
      if (!data) {
        data = await router.fetchHistory(asset.id, fromTs, toTs, '1d')
        if (data.length) cacheSet('eod', data, cacheKey)
      }
      data = data.slice(-days)
      setBars(data)

      if (data.length > 0) {
        const closes = data.map(b => b.adjClose ?? b.close)
        const ind = computeAll(closes)
        setIndicators(ind)
        setSignals(deriveSignals(closes, ind))
      }

      // Quote (short TTL, don't block on failure)
      router.fetchQuote(asset.id).then(setQuote).catch(() => {})
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }, [asset])

  useEffect(() => { load(range) }, [asset, range, load])

  const changeRange = r => { setRange(r); load(r) }

  const priceChange = (() => {
    if (bars.length < 2) return null
    const first = bars[0].adjClose ?? bars[0].close
    const last  = bars[bars.length - 1].adjClose ?? bars[bars.length - 1].close
    const pct = ((last - first) / first) * 100
    return { pct, positive: pct >= 0, label: `${pct >= 0 ? '+' : ''}${pct.toFixed(2)}%` }
  })()

  return { bars, indicators, signals, quote, range, loading, error, changeRange, priceChange }
}
