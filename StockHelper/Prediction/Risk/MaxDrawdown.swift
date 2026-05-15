import Foundation

struct DrawdownResult {
    let maxDrawdown: Double        // e.g. -0.35 = -35%
    let maxDrawdownPercent: String
    let peakIndex: Int
    let troughIndex: Int
    let recoveryIndex: Int?        // nil if not yet recovered
    let averageDrawdown: Double
}

enum MaxDrawdown {
    static func compute(prices: [Double]) -> DrawdownResult {
        guard prices.count >= 2 else {
            return DrawdownResult(maxDrawdown: 0, maxDrawdownPercent: "0%",
                                  peakIndex: 0, troughIndex: 0, recoveryIndex: nil, averageDrawdown: 0)
        }

        var maxDD = 0.0
        var peak = prices[0]
        var peakIdx = 0
        var troughIdx = 0
        var currentPeakIdx = 0
        var drawdowns: [Double] = []

        for i in 1..<prices.count {
            if prices[i] > peak {
                peak = prices[i]
                currentPeakIdx = i
            }
            let drawdown = (prices[i] - peak) / peak
            drawdowns.append(drawdown)
            if drawdown < maxDD {
                maxDD = drawdown
                peakIdx = currentPeakIdx
                troughIdx = i
            }
        }

        let recoveryIdx = findRecovery(prices: prices, peakIdx: peakIdx, peakPrice: prices[peakIdx], from: troughIdx)
        let avgDD = drawdowns.filter { $0 < 0 }.reduce(0, +) / max(Double(drawdowns.filter { $0 < 0 }.count), 1)

        return DrawdownResult(
            maxDrawdown: maxDD,
            maxDrawdownPercent: String(format: "%.1f%%", maxDD * 100),
            peakIndex: peakIdx,
            troughIndex: troughIdx,
            recoveryIndex: recoveryIdx,
            averageDrawdown: avgDD
        )
    }

    private static func findRecovery(prices: [Double], peakIdx: Int, peakPrice: Double, from troughIdx: Int) -> Int? {
        for i in troughIdx..<prices.count {
            if prices[i] >= peakPrice { return i }
        }
        return nil
    }
}
