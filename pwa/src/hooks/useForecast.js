import { useState, useCallback } from 'react'
import { router } from '../data/providers/router.js'
import { generateForecast } from '../prediction/forecast.js'

export function useForecast(asset) {
  const [forecast, setForecast] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [horizon, setHorizon] = useState(30)

  const run = useCallback(async (days) => {
    if (!asset) return
    setLoading(true); setError(null); setForecast(null)
    try {
      const toTs = Math.floor(Date.now() / 1000)
      const fromTs = Math.floor((Date.now() - 500 * 86400_000) / 1000) // ~500 days
      const bars = await router.fetchHistory(asset.id, fromTs, toTs, '1d')
      const result = await generateForecast(bars, asset, days)
      setForecast(result)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }, [asset])

  const changeHorizon = (days) => { setHorizon(days); run(days) }
  const generate = () => run(horizon)

  return { forecast, loading, error, horizon, changeHorizon, generate }
}
