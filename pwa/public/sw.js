const CACHE = 'stock-helper-v1'
const STATIC = ['/', '/index.html']

self.addEventListener('install', e =>
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(STATIC)))
)

self.addEventListener('fetch', e => {
  // Network-first for API calls, cache-first for static assets
  if (e.request.url.includes('/api/') || e.request.url.includes('finance.yahoo') || e.request.url.includes('alphavantage')) {
    e.respondWith(fetch(e.request).catch(() => caches.match(e.request)))
  } else {
    e.respondWith(
      caches.match(e.request).then(cached => cached || fetch(e.request))
    )
  }
})
