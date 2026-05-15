import Foundation

enum MACD {
    /// Standard MACD: EMA(12) - EMA(26), signal = EMA(9) of MACD, histogram = MACD - signal.
    static func compute(_ values: [Double], fast: Int = 12, slow: Int = 26, signal: Int = 9) -> MACDResult {
        let ema12 = EMA.compute(values, period: fast)
        let ema26 = EMA.compute(values, period: slow)

        let macdLine = zip(ema12, ema26).map { f, s in
            f.isNaN || s.isNaN ? Double.nan : f - s
        }

        // Compute EMA of MACD for the signal line
        // Only use valid (non-NaN) values for seeding
        let validIndices = macdLine.indices.filter { !macdLine[$0].isNaN }
        var signalLine = Array(repeating: Double.nan, count: macdLine.count)

        if validIndices.count >= signal, let firstValid = validIndices.first {
            let validMacd = validIndices.map { macdLine[$0] }
            let emaSignal = EMA.compute(validMacd, period: signal)
            for (offset, idx) in validIndices.enumerated() {
                signalLine[idx] = emaSignal[offset]
            }
            // Pad leading NaNs
            for i in 0..<firstValid {
                signalLine[i] = Double.nan
            }
        }

        let histogram = zip(macdLine, signalLine).map { m, s in
            m.isNaN || s.isNaN ? Double.nan : m - s
        }

        return MACDResult(macdLine: macdLine, signalLine: signalLine, histogram: histogram)
    }
}
