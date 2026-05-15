import { Star, Trash2, TrendingUp } from 'lucide-react'
import { useWatchlist } from '../hooks/useWatchlist.js'

export default function Watchlist({ onSelectAsset }) {
  const { items, remove } = useWatchlist()

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-slate-500 gap-3 px-8 text-center">
        <Star size={48} className="opacity-30" />
        <p className="text-sm">Your watchlist is empty.</p>
        <p className="text-xs">Tap the ★ on any asset to add it here.</p>
      </div>
    )
  }

  return (
    <div className="flex flex-col h-full">
      <div className="px-4 pt-5 pb-3">
        <h1 className="text-xl font-bold">Watchlist</h1>
        <p className="text-xs text-slate-400 mt-0.5">{items.length} {items.length === 1 ? 'asset' : 'assets'}</p>
      </div>
      <div className="flex-1 overflow-y-auto px-4 space-y-1.5">
        {items.map(asset => (
          <div
            key={asset.id}
            className="flex items-center bg-slate-800 rounded-xl overflow-hidden"
          >
            <button
              className="flex-1 flex items-center justify-between p-4 text-left active:bg-slate-700 transition-colors"
              onClick={() => onSelectAsset(asset)}
            >
              <div>
                <div className="font-semibold text-white">{asset.id}</div>
                <div className="text-xs text-slate-400 mt-0.5 max-w-[200px] truncate">{asset.name}</div>
              </div>
              <div className="text-right shrink-0">
                <div className="text-xs text-slate-500">{asset.exchange}</div>
                <div className="text-xs text-slate-500 mt-0.5">{asset.kind}</div>
              </div>
            </button>
            <button
              onClick={() => remove(asset.id)}
              className="px-4 py-4 text-slate-600 active:text-red-400 transition-colors"
            >
              <Trash2 size={17} />
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}
