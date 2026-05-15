import { Search as SearchIcon, X, TrendingUp } from 'lucide-react'
import { useSearch } from '../hooks/useSearch.js'
import { useWatchlist } from '../hooks/useWatchlist.js'

const KIND_COLOURS = {
  ETF: 'bg-purple-500/20 text-purple-300',
  ETN: 'bg-amber-500/20 text-amber-300',
  Stock: 'bg-blue-500/20 text-blue-300',
}

export default function Search({ onSelectAsset }) {
  const { query, setQuery, results, loading, error } = useSearch()
  const { isWatched } = useWatchlist()

  return (
    <div className="flex flex-col h-full">
      {/* Search bar */}
      <div className="px-4 pt-4 pb-3">
        <div className="relative">
          <SearchIcon size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Ticker or company name…"
            className="w-full bg-slate-800 rounded-xl pl-9 pr-9 py-3 text-sm text-white placeholder-slate-500 outline-none focus:ring-2 focus:ring-blue-500"
            autoCapitalize="characters"
            autoCorrect="off"
            spellCheck={false}
          />
          {query && (
            <button onClick={() => setQuery('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400">
              <X size={16} />
            </button>
          )}
        </div>
      </div>

      {/* Results */}
      <div className="flex-1 overflow-y-auto px-4 space-y-1">
        {loading && (
          <div className="flex items-center gap-2 py-8 justify-center text-slate-400 text-sm">
            <div className="w-4 h-4 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" />
            Searching…
          </div>
        )}
        {error && (
          <div className="py-8 text-center text-sm text-red-400">
            ⚠️ {error}
            <div className="mt-1 text-xs text-slate-500">Check your connection or try a different symbol</div>
          </div>
        )}
        {!loading && !error && results.length === 0 && query.length > 0 && (
          <div className="py-8 text-center text-slate-500 text-sm">No results for "{query}"</div>
        )}
        {!loading && !error && results.length === 0 && !query && (
          <div className="py-12 text-center text-slate-600 text-sm">
            <TrendingUp size={40} className="mx-auto mb-3 opacity-40" />
            Search US and European stocks, ETFs, ETNs
          </div>
        )}
        {results.map(asset => (
          <button
            key={asset.id}
            onClick={() => onSelectAsset(asset)}
            className="w-full flex items-center justify-between p-3 rounded-xl bg-slate-800/60 active:bg-slate-700 transition-colors text-left"
          >
            <div>
              <div className="flex items-center gap-2">
                <span className="font-semibold text-white">{asset.id}</span>
                {isWatched(asset.id) && <span className="text-yellow-400 text-xs">★</span>}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 truncate max-w-[200px]">{asset.name}</div>
            </div>
            <div className="flex flex-col items-end gap-1 shrink-0">
              <span className="text-xs text-slate-400">{asset.exchange}</span>
              <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${KIND_COLOURS[asset.kind] || KIND_COLOURS.Stock}`}>
                {asset.kind}
              </span>
            </div>
          </button>
        ))}
      </div>
    </div>
  )
}
