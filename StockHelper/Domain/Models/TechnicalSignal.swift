import Foundation

enum SignalDirection {
    case bullish, bearish, neutral
}

struct TechnicalSignal: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let direction: SignalDirection
    let description: String
}

struct IndicatorResult {
    let sma20: [Double]
    let sma50: [Double]
    let sma200: [Double]
    let ema12: [Double]
    let ema26: [Double]
    let rsi14: [Double]
    let macd: MACDResult
    let bollingerBands: BollingerResult
    let signals: [TechnicalSignal]
}

struct MACDResult {
    let macdLine: [Double]
    let signalLine: [Double]
    let histogram: [Double]
}

struct BollingerResult {
    let upper: [Double]
    let middle: [Double]
    let lower: [Double]
    let bandwidth: [Double]
    let percentB: [Double]
}
