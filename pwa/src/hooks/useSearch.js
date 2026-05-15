import { useState, useEffect, useRef } from 'react'
import { router } from '../data/providers/router.js'
import { cacheGet, cacheSet } from '../data/cache.js'

export function useSearch() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const timerRef = useRef(null)

  useEffect(() => {
    if (timerRef.current) clearTimeout(timerRef.current)
    if (!query.trim()) { setResults([]); setLoading(false); return }

    timerRef.current = setTimeout(async () => {
      setLoading(true); setError(null)
      try {
        const cached = cacheGet('search', query.toLowerCase())
        if (cached) { setResults(cached); return }
        const assets = await router.search(query.trim())
        cacheSet('search', assets, query.toLowerCase())
        setResults(assets)
      } catch (e) {
        setError(e.message)
        setResults([])
      } finally {
        setLoading(false)
      }
    }, 350)

    return () => clearTimeout(timerRef.current)
  }, [query])

  return { query, setQuery, results, loading, error }
}
