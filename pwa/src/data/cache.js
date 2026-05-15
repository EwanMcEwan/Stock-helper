const TTL = {
  search: 7 * 24 * 3600_000,
  eod: 24 * 3600_000,
  quote: 60_000,
  meta: 30 * 24 * 3600_000,
}

function key(type, ...parts) {
  return `sh:${type}:${parts.join(':')}`
}

export function cacheGet(type, ...parts) {
  try {
    const raw = localStorage.getItem(key(type, ...parts))
    if (!raw) return null
    const { data, ts } = JSON.parse(raw)
    if (Date.now() - ts > TTL[type]) { localStorage.removeItem(key(type, ...parts)); return null }
    return data
  } catch { return null }
}

export function cacheSet(type, data, ...parts) {
  try {
    localStorage.setItem(key(type, ...parts), JSON.stringify({ data, ts: Date.now() }))
  } catch {
    // storage full — evict oldest entry
    const oldest = Object.keys(localStorage)
      .filter(k => k.startsWith('sh:'))
      .sort((a, b) => {
        const ta = JSON.parse(localStorage.getItem(a) || '{}').ts || 0
        const tb = JSON.parse(localStorage.getItem(b) || '{}').ts || 0
        return ta - tb
      })[0]
    if (oldest) { localStorage.removeItem(oldest); cacheSet(type, data, ...parts) }
  }
}
