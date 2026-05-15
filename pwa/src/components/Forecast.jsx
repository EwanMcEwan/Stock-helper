import { ArrowLeft, AlertTriangle, RefreshCw } from 'lucide-react'
import { useForecast } from '../hooks/useForecast.js'
import ProbabilityCone from './ProbabilityCone.jsx'

const HORIZONS = [7, 14, 30, 60, 90]

function ConfidenceBar({ value }) {
  const pct = Math.round(value * 100)
  const colour = pct < 35 ? 'bg-red-500' : pct < 60 ? 'bg-amber-500' : 'bg-green-500'
  const label = pct < 35 ? 'Very Low' : pct < 50 ? 'Low' : pct < 70 ? 'Moderate' : 'High'
  return (
    <div>
      <div className="flex justify-between text-xs text-slate-400 mb-1">
        <span>Model Confidence</span>
        <span className="font-medium text-white">{pct}% — {label}</span>
      </div>
      <div className="h-1.5 bg-slate-700 rounded-full overflow-hidden">
        <div className={`h-full ${colour} rounded-full transition-all duration-700`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  )
}

export default function Forecast({ asset, onBack }) {
  const { forecast, loading, error, horizon, changeHorizon, generate } = useForecast(asset)

  return (
    <div className="flex flex-col h-full overflow-y-auto">
      {/* Header */}
      <div className="flex items-center gap-3 px-4 pt-4 pb-2 shrink-0">
        <button onClick={onBack} className="p-2 rounded-full active:bg-slate-700">
          <ArrowLeft size={20} />
        </button>
        <div>
          <h1 className="text-lg font-bold">Forecast — {asset.id}</h1>
          <p className="text-xs text-slate-400">Probabilistic estimate · not a guarantee</p>
        </div>
      </div>

      {/* Horizon picker */}
      <div className="px-4 pb-3">
        <p className="text-xs text-slate-400 mb-2">Horizon (trading days)</p>
        <div className="flex gap-2">
          {HORIZONS.map(d => (
            <button
              key={d}
              onClick={() => changeHorizon(d)}
              className={`flex-1 py-2 text-sm rounded-xl font-medium transition-colors ${
                horizon === d ? 'bg-blue-600 text-white' : 'bg-slate-800 text-slate-400'
              }`}
            >
              {d}d
            </button>
          ))}
        </div>
      </div>

      {/* Loading */}
      {loading && (
        <div className="flex flex-col items-center justify-center gap-3 py-16 text-slate-400">
          <div className="w-8 h-8 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" />
          <div className="text-sm">Running 2,000 simulations…</div>
        </div>
      )}

      {/* Error */}
      {error && !loading && (
        <div className="px-4 py-8 text-center">
          <div className="text-red-400 text-sm mb-3">⚠️ {error}</div>
          <button onClick={generate} className="flex items-center gap-1.5 mx-auto text-sm text-blue-400">
            <RefreshCw size={14} /> Try again
          </button>
        </div>
      )}

      {/* No forecast yet */}
      {!forecast && !loading && !error && (
        <div className="px-4 py-8 text-center text-slate-500 text-sm">
          Select a horizon above to run the forecast
          <button onClick={generate} className="block mt-3 mx-auto px-4 py-2 bg-blue-600 text-white rounded-xl text-sm">
            Run now
          </button>
        </div>
      )}

      {/* Forecast results */}
      {forecast && !loading && (
        <div className="px-4 pb-8 space-y-5">
          {/* Confidence */}
          <ConfidenceBar value={forecast.confidence} />

          {/* Stats row */}
          <div className="grid grid-cols-3 gap-2">
            <Stat label="Ann. Volatility" value={`${(forecast.annVol * 100).toFixed(1)}%`} />
            <Stat label="Sharpe Ratio" value={forecast.risk.sharpe.toFixed(2)} />
            <Stat label="Max Drawdown" value={forecast.risk.maxDrawdown.label} negative />
          </div>

          {/* Cone chart */}
          <div>
            <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2">Price Probability Cone</h2>
            <ProbabilityCone forecast={forecast} />
            <div className="flex gap-4 mt-2 text-xs text-slate-500">
              <span className="flex items-center gap-1"><span className="w-3 h-1.5 bg-blue-500/20 rounded inline-block" /> 5–95th %ile</span>
              <span className="flex items-center gap-1"><span className="w-3 h-1.5 bg-blue-500/40 rounded inline-block" /> 25–75th %ile</span>
              <span className="flex items-center gap-1"><span className="w-3 h-0.5 bg-blue-400 inline-block" /> Median</span>
            </div>
          </div>

          {/* Probabilities */}
          <div>
            <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2">Outcome Probabilities</h2>
            <div className="space-y-1">
              {forecast.probabilities.map(p => (
                <div key={p.label} className="flex items-center justify-between bg-slate-800 rounded-xl px-3 py-2.5">
                  <span className="text-sm text-slate-300">{p.label}</span>
                  <span className={`text-sm font-semibold ${p.probability > 0.5 ? 'text-green-400' : 'text-red-400'}`}>
                    {(p.probability * 100).toFixed(1)}%
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Technical signals */}
          {forecast.signals?.length > 0 && (
            <div>
              <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2">At Forecast Date</h2>
              <div className="flex gap-2 overflow-x-auto pb-1">
                {forecast.signals.map(s => (
                  <div key={s.name} className="shrink-0 bg-slate-800 rounded-xl p-3 min-w-[110px]">
                    <div className="text-xs text-slate-400">{s.name}</div>
                    <div className={`text-sm font-bold mt-0.5 ${s.direction === 'bull' ? 'text-green-400' : s.direction === 'bear' ? 'text-red-400' : 'text-slate-400'}`}>
                      {s.value}
                    </div>
                    <div className="text-xs text-slate-500 mt-0.5">{s.label}</div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Disclaimer */}
          <div className="bg-amber-500/10 border border-amber-500/20 rounded-2xl p-4">
            <div className="flex items-center gap-1.5 text-amber-400 text-xs font-semibold mb-1.5">
              <AlertTriangle size={13} /> Important Disclaimer
            </div>
            <p className="text-xs text-slate-400 leading-relaxed">{forecast.disclaimer}</p>
          </div>
        </div>
      )}
    </div>
  )
}

function Stat({ label, value, negative }) {
  return (
    <div className="bg-slate-800 rounded-xl p-3">
      <div className="text-xs text-slate-400">{label}</div>
      <div className={`text-base font-bold mt-0.5 ${negative ? 'text-red-400' : 'text-white'}`}>{value}</div>
    </div>
  )
}
