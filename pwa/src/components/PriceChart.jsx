import { ComposedChart, Line, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts'
import { useState } from 'react'

const fmt = (ts) => new Date(ts).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })

export default function PriceChart({ bars, indicators, range }) {
  const [show, setShow] = useState({ sma20: true, sma50: false, bb: false })

  if (!bars.length) return null

  const closes = bars.map(b => b.adjClose ?? b.close)
  const data = bars.map((b, i) => ({
    date: b.date,
    close: closes[i],
    sma20: indicators?.sma20?.[i],
    sma50: indicators?.sma50?.[i],
    bbUpper: indicators?.bb?.upper?.[i],
    bbLower: indicators?.bb?.lower?.[i],
    volume: b.volume,
    // Simple "candle" colour
    fill: closes[i] >= b.open ? '#22c55e' : '#ef4444',
  })).filter(d => !isNaN(d.close))

  const yMin = Math.min(...data.map(d => d.close)) * 0.98
  const yMax = Math.max(...data.map(d => d.close)) * 1.02

  const stride = Math.max(1, Math.floor(data.length / 4))

  return (
    <div>
      {/* Toggle buttons */}
      <div className="flex gap-2 mb-2 flex-wrap">
        {[['sma20', 'SMA 20', '#f97316'], ['sma50', 'SMA 50', '#3b82f6'], ['bb', 'Bollinger', '#a855f7']].map(([k, label, color]) => (
          <button
            key={k}
            onClick={() => setShow(s => ({ ...s, [k]: !s[k] }))}
            className="text-xs px-2 py-0.5 rounded-full border transition-all"
            style={show[k] ? { background: color, borderColor: color, color: '#fff' } : { borderColor: color, color: color }}
          >
            {label}
          </button>
        ))}
      </div>

      <ResponsiveContainer width="100%" height={220}>
        <ComposedChart data={data} margin={{ top: 4, right: 8, bottom: 0, left: 0 }}>
          <XAxis dataKey="date" tickFormatter={fmt} interval={stride} tick={{ fontSize: 10, fill: '#94a3b8' }} tickLine={false} axisLine={false} />
          <YAxis domain={[yMin, yMax]} tick={{ fontSize: 10, fill: '#94a3b8' }} tickLine={false} axisLine={false} orientation="right" tickFormatter={v => v.toFixed(0)} width={50} />
          <Tooltip
            contentStyle={{ background: '#1e293b', border: 'none', borderRadius: 8, fontSize: 11 }}
            labelFormatter={ts => new Date(ts).toLocaleDateString()}
            formatter={(v, name) => [typeof v === 'number' ? v.toFixed(2) : v, name]}
          />

          {/* Bollinger bands — behind price */}
          {show.bb && <Line dataKey="bbUpper" dot={false} strokeWidth={1} stroke="#a855f7" strokeDasharray="3 3" strokeOpacity={0.6} name="BB Upper" />}
          {show.bb && <Line dataKey="bbLower" dot={false} strokeWidth={1} stroke="#a855f7" strokeDasharray="3 3" strokeOpacity={0.6} name="BB Lower" />}

          {/* Price line */}
          <Line dataKey="close" dot={false} strokeWidth={2} stroke="#60a5fa" name="Price" />

          {/* Moving averages */}
          {show.sma20 && <Line dataKey="sma20" dot={false} strokeWidth={1.5} stroke="#f97316" name="SMA 20" />}
          {show.sma50 && <Line dataKey="sma50" dot={false} strokeWidth={1.5} stroke="#3b82f6" name="SMA 50" />}
        </ComposedChart>
      </ResponsiveContainer>

      {/* Volume bars */}
      <ResponsiveContainer width="100%" height={48}>
        <ComposedChart data={data} margin={{ top: 0, right: 8, bottom: 0, left: 0 }}>
          <Bar dataKey="volume" fill="#334155" radius={[1, 1, 0, 0]} name="Volume" />
          <XAxis hide /> <YAxis hide />
        </ComposedChart>
      </ResponsiveContainer>
    </div>
  )
}
