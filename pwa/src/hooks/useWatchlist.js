import { useState, useEffect } from 'react'

const KEY = 'sh:watchlist'

export function useWatchlist() {
  const [items, setItems] = useState(() => {
    try { return JSON.parse(localStorage.getItem(KEY) || '[]') } catch { return [] }
  })

  useEffect(() => {
    localStorage.setItem(KEY, JSON.stringify(items))
  }, [items])

  const add = (asset) => setItems(prev =>
    prev.find(a => a.id === asset.id) ? prev : [...prev, asset]
  )

  const remove = (id) => setItems(prev => prev.filter(a => a.id !== id))

  const isWatched = (id) => items.some(a => a.id === id)

  return { items, add, remove, isWatched }
}
