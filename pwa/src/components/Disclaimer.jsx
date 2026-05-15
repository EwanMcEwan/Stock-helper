import { TrendingUp, AlertTriangle } from 'lucide-react'
import { DISCLAIMER } from '../prediction/forecast.js'

export default function Disclaimer({ onAccept }) {
  return (
    <div className="flex flex-col min-h-screen bg-slate-950 px-6 py-safe">
      <div className="flex flex-col items-center pt-16 pb-8">
        <div className="w-20 h-20 rounded-3xl bg-blue-600 flex items-center justify-center mb-4">
          <TrendingUp size={40} className="text-white" />
        </div>
        <h1 className="text-2xl font-bold text-white">Stock Helper</h1>
        <p className="text-slate-400 text-sm mt-1">Educational & Informational Use Only</p>
      </div>

      <div className="flex-1 overflow-y-auto">
        <div className="bg-amber-500/10 border border-amber-500/20 rounded-2xl p-5">
          <div className="flex items-center gap-2 text-amber-400 font-semibold mb-3">
            <AlertTriangle size={16} />
            Please read before continuing
          </div>
          <p className="text-sm text-slate-300 leading-relaxed">{DISCLAIMER}</p>
          <ul className="mt-4 space-y-2 text-sm text-slate-300">
            {[
              'Forecasts are probabilistic ranges, not guarantees.',
              'Past performance does not indicate future results.',
              'This app does not provide financial advice.',
              'Always consult a qualified adviser before investing.',
            ].map(item => (
              <li key={item} className="flex gap-2">
                <span className="text-amber-400 shrink-0">•</span>
                {item}
              </li>
            ))}
          </ul>
        </div>
      </div>

      <div className="pt-6 pb-4">
        <button
          onClick={onAccept}
          className="w-full py-4 bg-blue-600 rounded-2xl text-white font-semibold text-base active:bg-blue-700 transition-colors"
        >
          I Understand — Continue
        </button>
        <p className="text-xs text-slate-600 text-center mt-3">You can view this disclaimer again in Settings</p>
      </div>
    </div>
  )
}
