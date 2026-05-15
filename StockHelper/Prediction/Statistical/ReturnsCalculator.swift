import Foundation

struct ReturnStats {
    let logReturns: [Double]
    let mean: Double             // mean daily log return
    let variance: Double         // daily variance
    let annualisedDrift: Double  // μ - σ²/2 (Itô correction for GBM)
    let annualisedVolatility: Double

    static let tradingDaysPerYear: Double = 252
}

enum ReturnsCalculator {
    func compute(_ prices: [Double]) -> ReturnStats {
        guard prices.count > 1 else {
            return ReturnStats(logReturns: [], mean: 0, variance: 0,
                               annualisedDrift: 0, annualisedVolatility: 0)
        }

        let logReturns: [Double] = zip(prices, prices.dropFirst()).compactMap { prev, curr in
            guard prev > 0, curr > 0 else { return nil }
            return log(curr / prev)
        }

        let n = Double(logReturns.count)
        let mean = logReturns.reduce(0, +) / n
        let variance = logReturns.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / (n - 1)
        let dailyStd = sqrt(variance)

        let annVol = dailyStd * sqrt(ReturnStats.tradingDaysPerYear)
        // Drift for GBM: annualised (μ - σ²/2)
        let annDrift = mean * ReturnStats.tradingDaysPerYear - 0.5 * annVol * annVol

        return ReturnStats(
            logReturns: logReturns,
            mean: mean,
            variance: variance,
            annualisedDrift: annDrift,
            annualisedVolatility: annVol
        )
    }
}
