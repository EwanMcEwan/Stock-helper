import Foundation

enum SharpeRatio {
    /// Annualised Sharpe Ratio.
    /// - Parameter riskFreeRate: Annualised risk-free rate (e.g. 0.05 = 5%).
    static func compute(logReturns: [Double], riskFreeRate: Double = 0.05) -> Double {
        guard logReturns.count > 1 else { return 0 }

        let n = Double(logReturns.count)
        let mean = logReturns.reduce(0, +) / n
        let variance = logReturns.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / (n - 1)
        let dailyStd = sqrt(variance)

        guard dailyStd > 0 else { return 0 }

        let dailyRiskFree = riskFreeRate / ReturnStats.tradingDaysPerYear
        let dailySharpe = (mean - dailyRiskFree) / dailyStd
        return dailySharpe * sqrt(ReturnStats.tradingDaysPerYear)
    }

    /// Sortino Ratio (penalises only downside deviation).
    static func sortino(logReturns: [Double], riskFreeRate: Double = 0.05) -> Double {
        guard logReturns.count > 1 else { return 0 }

        let n = Double(logReturns.count)
        let mean = logReturns.reduce(0, +) / n
        let dailyRiskFree = riskFreeRate / ReturnStats.tradingDaysPerYear

        let negativeReturns = logReturns.filter { $0 < dailyRiskFree }
        guard !negativeReturns.isEmpty else { return Double.infinity }

        let downsideVariance = negativeReturns.map { ($0 - dailyRiskFree) * ($0 - dailyRiskFree) }.reduce(0, +) / n
        let downsideStd = sqrt(downsideVariance)
        guard downsideStd > 0 else { return 0 }

        return ((mean - dailyRiskFree) / downsideStd) * sqrt(ReturnStats.tradingDaysPerYear)
    }
}
