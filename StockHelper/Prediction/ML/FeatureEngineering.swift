import Foundation

struct FeatureVector {
    let normalizedReturns: [Double]     // last N log returns, standardized
    let rsi: Double                      // 0...1 normalized
    let macdHistogram: Double            // normalized
    let bollingerPctB: Double            // 0...1
    let volumeRatio: Double              // volume / 20d avg volume
    let volatilityRank: Double           // current vol vs. historical range
}

enum FeatureEngineering {
    static let sequenceLength = 60  // LSTM lookback window in days

    static func buildFeatures(bars: [PriceBar], indicators: IndicatorResult) -> [FeatureVector]? {
        guard bars.count >= sequenceLength else { return nil }

        let closes = bars.map(\.effectiveClose)
        let volumes = bars.map(\.volume)

        let logReturns = zip(closes, closes.dropFirst()).map { log($1 / $0) }
        let (mean, std) = meanStd(logReturns)

        let avgVolume20 = rollingMean(volumes, period: 20)

        var features: [FeatureVector] = []
        let start = sequenceLength
        for i in start..<bars.count {
            let returnWindow = Array(logReturns[(i - sequenceLength)..<i])
            let normReturns = returnWindow.map { std > 0 ? ($0 - mean) / std : 0 }

            let rsiRaw = indicators.rsi14[i]
            let rsi = rsiRaw.isNaN ? 0.5 : rsiRaw / 100.0

            let macdH = indicators.macd.histogram[i]
            let macdNorm = macdH.isNaN ? 0.0 : tanh(macdH / (closes[i] * 0.01))

            let pctB = indicators.bollingerBands.percentB[i]
            let bb = pctB.isNaN ? 0.5 : min(max(pctB, 0), 1)

            let vol20 = avgVolume20[i]
            let volRatio = vol20 > 0 ? min(volumes[i] / vol20, 3.0) / 3.0 : 0.5

            features.append(FeatureVector(
                normalizedReturns: normReturns,
                rsi: rsi,
                macdHistogram: macdNorm,
                bollingerPctB: bb,
                volumeRatio: volRatio,
                volatilityRank: 0.5  // placeholder — would use rolling vol percentile
            ))
        }
        return features
    }

    private static func meanStd(_ values: [Double]) -> (mean: Double, std: Double) {
        guard !values.isEmpty else { return (0, 1) }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        return (mean, max(sqrt(variance), 1e-8))
    }

    private static func rollingMean(_ values: [Double], period: Int) -> [Double] {
        var result = Array(repeating: 0.0, count: values.count)
        var sum = 0.0
        for i in 0..<values.count {
            sum += values[i]
            if i >= period { sum -= values[i - period] }
            let n = min(i + 1, period)
            result[i] = sum / Double(n)
        }
        return result
    }
}
