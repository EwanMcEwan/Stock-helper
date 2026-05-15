import { useState, useEffect } from 'react'
import { Search as SearchIcon, Star, Settings as SettingsIcon } from 'lucide-react'
import Disclaimer from './components/Disclaimer.jsx'
import Search from './components/Search.jsx'
import AssetDetail from './components/AssetDetail.jsx'
import Forecast from './components/Forecast.jsx'
import Watchlist from './components/Watchlist.jsx'
import Settings from './components/Settings.jsx'

const TABS = [
  { id: 'search',    label: 'Search',   Icon: SearchIcon },
  { id: 'watchlist', label: 'Watchlist', Icon: Star },
  { id: 'settings',  label: 'Settings',  Icon: SettingsIcon },
]

export default function App() {
  const [accepted, setAccepted] = useState(() => localStorage.getItem('sh:accepted') === '1')
  const [tab, setTab] = useState('search')
  const [selectedAsset, setSelectedAsset] = useState(null)
  const [forecastAsset, setForecastAsset] = useState(null)

  const accept = () => { localStorage.setItem('sh:accepted', '1'); setAccepted(true) }

  // Register service worker
  useEffect(() => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(() => {})
    }
  }, [])

  if (!accepted) return <Disclaimer onAccept={accept} />

  const handleSelectAsset = (asset) => { setSelectedAsset(asset); setForecastAsset(null) }
  const handleForecast = (asset) => setForecastAsset(asset)
  const handleBack = () => {
    if (forecastAsset) { setForecastAsset(null); return }
    setSelectedAsset(null)
  }

  // Detail / Forecast screens take over the full view
  if (forecastAsset) {
    return (
      <div className="flex flex-col h-screen bg-slate-950 text-white overflow-hidden">
        <div className="flex-1 overflow-hidden">
          <Forecast asset={forecastAsset} onBack={handleBack} />
        </div>
      </div>
    )
  }

  if (selectedAsset) {
    return (
      <div className="flex flex-col h-screen bg-slate-950 text-white overflow-hidden">
        <div className="flex-1 overflow-hidden">
          <AssetDetail asset={selectedAsset} onBack={handleBack} onForecast={handleForecast} />
        </div>
      </div>
    )
  }

  return (
    <div className="flex flex-col h-screen bg-slate-950 text-white overflow-hidden">
      {/* Screen */}
      <div className="flex-1 overflow-hidden">
        {tab === 'search'    && <Search    onSelectAsset={handleSelectAsset} />}
        {tab === 'watchlist' && <Watchlist onSelectAsset={handleSelectAsset} />}
        {tab === 'settings'  && <Settings />}
      </div>

      {/* Tab bar */}
      <nav className="shrink-0 bg-slate-900 border-t border-slate-800 flex pb-safe">
        {TABS.map(({ id, label, Icon }) => {
          const active = tab === id
          return (
            <button
              key={id}
              onClick={() => setTab(id)}
              className="flex-1 flex flex-col items-center justify-center py-3 gap-0.5 transition-colors"
            >
              <Icon size={22} className={active ? 'text-blue-400' : 'text-slate-600'} fill={active && id === 'watchlist' ? 'currentColor' : 'none'} />
              <span className={`text-[10px] font-medium ${active ? 'text-blue-400' : 'text-slate-600'}`}>{label}</span>
            </button>
          )
        })}
      </nav>
    </div>
  )
}
