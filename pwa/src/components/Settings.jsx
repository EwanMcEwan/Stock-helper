import { useState } from 'react'
import { Eye, EyeOff, ExternalLink, AlertTriangle } from 'lucide-react'
import { DISCLAIMER } from '../prediction/forecast.js'

function SecretField({ label, storageKey, placeholder }) {
  const [val, setVal] = useState(() => localStorage.getItem(storageKey) || '')
  const [show, setShow] = useState(false)
  const save = (v) => { setVal(v); localStorage.setItem(storageKey, v) }

  return (
    <div>
      <label className="text-xs text-slate-400 block mb-1">{label}</label>
      <div className="relative">
        <input
          type={show ? 'text' : 'password'}
          value={val}
          onChange={e => save(e.target.value)}
          placeholder={placeholder}
          className="w-full bg-slate-800 rounded-xl px-3 pr-10 py-2.5 text-sm text-white placeholder-slate-600 outline-none focus:ring-2 focus:ring-blue-500"
          autoCapitalize="none"
          autoCorrect="off"
          spellCheck={false}
        />
        <button onClick={() => setShow(s => !s)} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500">
          {show ? <EyeOff size={15} /> : <Eye size={15} />}
        </button>
      </div>
    </div>
  )
}

function ProxyField() {
  const DEFAULT = 'https://corsproxy.io/?'
  const [val, setVal] = useState(() => localStorage.getItem('sh:corsProxy') || DEFAULT)
  const save = (v) => { setVal(v); localStorage.setItem('sh:corsProxy', v || DEFAULT) }

  return (
    <div>
      <label className="text-xs text-slate-400 block mb-1">CORS Proxy URL</label>
      <input
        value={val}
        onChange={e => save(e.target.value)}
        className="w-full bg-slate-800 rounded-xl px-3 py-2.5 text-sm text-white outline-none focus:ring-2 focus:ring-blue-500"
        autoCapitalize="none"
        autoCorrect="off"
        spellCheck={false}
      />
      <p className="text-xs text-slate-600 mt-1">Used to reach Yahoo Finance from your browser. Default: corsproxy.io</p>
    </div>
  )
}

function Section({ title, children }) {
  return (
    <div>
      <h2 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">{title}</h2>
      <div className="bg-slate-800 rounded-2xl p-4 space-y-4">{children}</div>
    </div>
  )
}

export default function Settings() {
  const version = '0.1.0'

  return (
    <div className="flex flex-col h-full overflow-y-auto">
      <div className="px-4 pt-5 pb-3">
        <h1 className="text-xl font-bold">Settings</h1>
      </div>
      <div className="px-4 space-y-5 pb-8">

        <Section title="API Keys (optional)">
          <SecretField label="Alpha Vantage Key" storageKey="sh:avKey" placeholder="Paste key for higher limits" />
          <SecretField label="Finnhub Key" storageKey="sh:fhKey" placeholder="Paste key for higher limits" />
          <p className="text-xs text-slate-600 leading-relaxed">
            Without keys the app uses Yahoo Finance via a CORS proxy. Free keys from{' '}
            <span className="text-blue-400">alphavantage.co</span> and{' '}
            <span className="text-blue-400">finnhub.io</span> unlock more requests per day.
          </p>
        </Section>

        <Section title="Network">
          <ProxyField />
        </Section>

        <Section title="About">
          <div className="flex justify-between text-sm">
            <span className="text-slate-400">Version</span>
            <span className="text-white">{version}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-slate-400">Platform</span>
            <span className="text-white">PWA (Safari)</span>
          </div>
        </Section>

        {/* Full disclaimer */}
        <div className="bg-amber-500/10 border border-amber-500/20 rounded-2xl p-4">
          <div className="flex items-center gap-1.5 text-amber-400 text-xs font-semibold mb-2">
            <AlertTriangle size={13} /> Full Disclaimer
          </div>
          <p className="text-xs text-slate-400 leading-relaxed">{DISCLAIMER}</p>
        </div>

        <p className="text-xs text-slate-600 text-center">Stock Helper · Educational use only · Not financial advice</p>
      </div>
    </div>
  )
}
