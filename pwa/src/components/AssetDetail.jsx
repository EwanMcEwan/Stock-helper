import { ArrowLeft, Star, TrendingUp, TrendingDown, BarChart2 } from 'lucide-react'
import { useAssetDetail, RANGES } from '../hooks/useAssetDetail.js'
import { useWatchlist } from '../hooks/useWatchlist.js'
import PriceChart from './PriceChart.jsx'

const DIR_CLASS = { bull: 'text-green-400', bear: 'text-red-400', neutral: 'text-slate-400' }

export default function AssetDetail({ asset, onBack, onForecast }) {
  const { bars, indicators, signals, quote, range, loading, error, changeRange, priceChange } = useAssetDetail(asset)
  const { isWatched, add, remove } = useWatchlist()
  const watched = isWatched(asset.id)

  return (
    <div className="flex flex-col h-full overflow-y-auto">
      {/* Header */}
      <div className="flex items-center gap-3 px-4 pt-4 pb-2 shrink-0">
        <button onClick={onBack} className="p-2 rounded-full active:bg-slate-700">
          <ArrowLeft size={20} />
        </button>
        <div className="flex-1">
          <div className="flex items-baseline gap-2">
            <h1 className="text-xl font-bold">{asset.id}</h1>
            {quote && (
              <span className={`text-sm font-medium ${quote.change >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                {quote.change >= 0 ? '+' : ''}{quote.changePercent.toFixed(2)}%
              </span>
            )}
          </div>
          <p className="text-xs text-slate-400 truncate">{asset.name}</p>
        </div>
        <button
          onClick={() => watched ? remove(asset.id) : add(asset)}
          className={`p-2 rounded-full transition-colors ${watched ? 'text-yellow-400' : 'text-slate-500'}`}
        >
          <Star size={20} fill={watched ? 'currentColor' : 'none'} />
        </button>
      </div>

      {/* Price */}
      {quote && (
        <div className="px-4 pb-1">
          <div className="text-3xl font-bold">{quote.price.toFixed(2)} <span className="text-sm text-slate-400">{asset.currency}</span></div>
        </div>
      )}

      {/* Range picker */}
      <div className="flex gap-1 px-4 py-2 shrink-0">
        {Object.keys(RANGES).map(r => (
          <button
            key={r}
            onClick={() => changeRange(r)}
            className={`flex-1 py-1.5 text-xs rounded-lg font-medium transition-colors ${
              range === r ? 'bg-blue-600 text-white' : 'bg-slate-800 text-slate-400'
            }`}
          >
            {r}
          </button>
        ))}
      </div>

      {/* Price change for range */}
      {priceChange && (
        <div className="px-4 pb-1 flex items-center gap-1">
          {priceChange.positive ? <TrendingUp size={14} className="text-green-400" /> : <TrendingDown size={14} className="text-red-400" />}
          <span className={`text-sm font-medium ${priceChange.positive ? 'text-green-400' : 'text-red-400'}`}>
            {priceChange.label} ({range})
          </span>
        </div>
      )}

      {/* Chart */}
      <div className="px-4">
        {loading && (
          <div className="flex items-center justify-center h-48 text-slate-400 text-sm gap-2">
            <div className="w-4 h-4 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" />
            Loading chart…
          </div>
        )}
        {error && <div className="text-red-400 text-sm py-8 text-center">⚠️ {error}</div>}
        {!loading && !error && bars.length > 0 && (
          <PriceChart bars={bars} indicators={indicators} range={range} />
        )}
      </div>

      {/* Technical Signals */}
      {signals.length > 0 && (
        <div className="px-4 mt-3">
          <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2">Technical Signals</h2>
          <div className="flex gap-2 overflow-x-auto pb-1">
            {signals.map(s => (
              <div key={s.name} className="shrink-0 bg-slate-800 rounded-xl p-3 min-w-[120px]">
                <div className="text-xs text-slate-400">{s.name}</div>
                <div className={`text-sm font-bold mt-0.5 ${DIR_CLASS[s.direction]}`}>{s.value}</div>
                <div className="text-xs text-slate-500 mt-0.5">{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Forecast CTA */}
      <div className="px-4 mt-4 mb-6">
        <button
          onClick={() => onForecast(asset)}
          className="w-full flex items-center justify-center gap-2 py-3.5 bg-blue-600 rounded-2xl font-semibold text-white active:bg-blue-700 transition-colors"
        >
          <BarChart2 size={18} />
          Generate Forecast
        </button>
      </div>
    </div>
  )
}
