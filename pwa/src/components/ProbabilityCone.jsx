import { AreaChart, Area, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, ReferenceLine, ComposedChart } from 'recharts'

export default function ProbabilityCone({ forecast }) {
  const { bands, startPrice, horizonDays } = forecast

  const data = bands.p5.map((_, i) => ({
    day: i,
    p5_95: [bands.p5[i], bands.p95[i]],
    p25_75: [bands.p25[i], bands.p75[i]],
    median: bands.p50[i],
    start: startPrice,
  }))

  const allPrices = [...bands.p5, ...bands.p95]
  const yMin = Math.min(...allPrices) * 0.98
  const yMax = Math.max(...allPrices) * 1.02

  const stride = Math.max(1, Math.floor(horizonDays / 4))

  return (
    <ResponsiveContainer width="100%" height={220}>
      <ComposedChart data={data} margin={{ top: 4, right: 8, bottom: 0, left: 0 }}>
        <XAxis
          dataKey="day"
          label={{ value: 'Trading days', position: 'insideBottom', offset: -2, fontSize: 10, fill: '#64748b' }}
          tick={{ fontSize: 10, fill: '#94a3b8' }} tickLine={false} axisLine={false}
          interval={stride}
        />
        <YAxis
          domain={[yMin, yMax]} orientation="right"
          tick={{ fontSize: 10, fill: '#94a3b8' }} tickLine={false} axisLine={false}
          tickFormatter={v => v.toFixed(0)} width={52}
        />
        <Tooltip
          contentStyle={{ background: '#1e293b', border: 'none', borderRadius: 8, fontSize: 11 }}
          formatter={(v, name) => Array.isArray(v) ? [`${v[0].toFixed(2)} – ${v[1].toFixed(2)}`, name] : [v?.toFixed(2), name]}
        />

        {/* 5–95% band */}
        <Area dataKey="p5_95" stroke="none" fill="#3b82f6" fillOpacity={0.10} name="5–95th %" />

        {/* 25–75% band */}
        <Area dataKey="p25_75" stroke="none" fill="#3b82f6" fillOpacity={0.22} name="25–75th %" />

        {/* Median */}
        <Line dataKey="median" dot={false} strokeWidth={2} stroke="#60a5fa" name="Median" />

        {/* Start price reference */}
        <ReferenceLine y={startPrice} stroke="#475569" strokeDasharray="4 2" />
      </ComposedChart>
    </ResponsiveContainer>
  )
}
