import Foundation

enum RSI {
    /// Wilder's RSI using exponential smoothing (standard definition).
    static func compute(_ values: [Double], period: Int = 14) -> [Double] {
        guard values.count > period else {
            return Array(repeating: Double.nan, count: values.count)
        }

        var result = Array(repeating: Double.nan, count: values.count)
        var gains = 0.0, losses = 0.0

        // Seed averages from first period changes
        for i in 1...period {
            let change = values[i] - values[i - 1]
            if change > 0 { gains += change } else { losses += -change }
        }
        var avgGain = gains / Double(period)
        var avgLoss = losses / Double(period)
        result[period] = rsi(avgGain: avgGain, avgLoss: avgLoss)

        // Wilder's smoothing
        for i in (period + 1)..<values.count {
            let change = values[i] - values[i - 1]
            let g = change > 0 ? change : 0
            let l = change < 0 ? -change : 0
            avgGain = (avgGain * Double(period - 1) + g) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + l) / Double(period)
            result[i] = rsi(avgGain: avgGain, avgLoss: avgLoss)
        }
        return result
    }

    private static func rsi(avgGain: Double, avgLoss: Double) -> Double {
        guard avgLoss != 0 else { return 100 }
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
}
