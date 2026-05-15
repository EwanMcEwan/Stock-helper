import Foundation

final class ComputeIndicatorsUseCase {

    func execute(bars: [PriceBar]) -> IndicatorResult {
        let closes = bars.map(\.effectiveClose)

        let sma20  = SMA.compute(closes, period: 20)
        let sma50  = SMA.compute(closes, period: 50)
        let sma200 = SMA.compute(closes, period: 200)
        let ema12  = EMA.compute(closes, period: 12)
        let ema26  = EMA.compute(closes, period: 26)
        let rsi14  = RSI.compute(closes, period: 14)
        let macd   = MACD.compute(closes)
        let bb     = BollingerBands.compute(closes, period: 20, multiplier: 2.0)

        let signals = deriveSignals(
            closes: closes,
            rsi: rsi14,
            macd: macd,
            bb: bb,
            sma20: sma20,
            sma50: sma50
        )

        return IndicatorResult(
            sma20: sma20, sma50: sma50, sma200: sma200,
            ema12: ema12, ema26: ema26,
            rsi14: rsi14,
            macd: macd,
            bollingerBands: bb,
            signals: signals
        )
    }

    private func deriveSignals(
        closes: [Double],
        rsi: [Double],
        macd: MACDResult,
        bb: BollingerResult,
        sma20: [Double],
        sma50: [Double]
    ) -> [TechnicalSignal] {
        var signals: [TechnicalSignal] = []

        if let lastRSI = rsi.last {
            let dir: SignalDirection = lastRSI < 30 ? .bullish : lastRSI > 70 ? .bearish : .neutral
            signals.append(TechnicalSignal(
                name: "RSI(14)",
                value: lastRSI,
                direction: dir,
                description: lastRSI < 30 ? "Oversold" : lastRSI > 70 ? "Overbought" : "Neutral"
            ))
        }

        if let lastMACD = macd.histogram.last {
            let dir: SignalDirection = lastMACD > 0 ? .bullish : lastMACD < 0 ? .bearish : .neutral
            signals.append(TechnicalSignal(
                name: "MACD Histogram",
                value: lastMACD,
                direction: dir,
                description: lastMACD > 0 ? "Positive momentum" : "Negative momentum"
            ))
        }

        if let close = closes.last, let upper = bb.upper.last, let lower = bb.lower.last {
            let dir: SignalDirection = close > upper ? .bearish : close < lower ? .bullish : .neutral
            signals.append(TechnicalSignal(
                name: "Bollinger Bands",
                value: bb.percentB.last ?? 0.5,
                direction: dir,
                description: close > upper ? "Price above upper band" : close < lower ? "Price below lower band" : "Price within bands"
            ))
        }

        if let close = closes.last, let s20 = sma20.last, let s50 = sma50.last {
            let dir: SignalDirection = (s20 > s50 && close > s20) ? .bullish : (s20 < s50 && close < s20) ? .bearish : .neutral
            signals.append(TechnicalSignal(
                name: "SMA Trend",
                value: close - s50,
                direction: dir,
                description: s20 > s50 ? "SMA20 above SMA50 (uptrend)" : "SMA20 below SMA50 (downtrend)"
            ))
        }

        return signals
    }
}
