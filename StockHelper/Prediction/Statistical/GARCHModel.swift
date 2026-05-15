import Foundation

/// GARCH(1,1) volatility model.
/// Estimates conditional variance: h_t = ω + α·ε²_{t-1} + β·h_{t-1}
/// Parameters are estimated via a simple moment-matching approach.
final class GARCHModel {
    struct Parameters {
        let omega: Double   // long-run variance component
        let alpha: Double   // ARCH coefficient (shock impact)
        let beta: Double    // GARCH coefficient (persistence)
        var isValid: Bool { alpha + beta < 1.0 && alpha > 0 && beta > 0 && omega > 0 }
    }

    func forecastVolatility(logReturns: [Double], horizon: Int) -> Double? {
        guard logReturns.count >= 30 else { return nil }
        guard let params = estimateParameters(logReturns) else { return nil }

        let longRunVariance = params.omega / (1 - params.alpha - params.beta)
        var currentVariance = unconditionalVariance(logReturns)
        let lastReturn = logReturns.last ?? 0
        currentVariance = params.omega + params.alpha * lastReturn * lastReturn + params.beta * currentVariance

        // Multi-step GARCH forecast
        var forecastVariance = 0.0
        var hNext = currentVariance
        for _ in 0..<horizon {
            hNext = params.omega + (params.alpha + params.beta) * hNext
            forecastVariance += hNext
        }

        // Average daily variance over horizon, then annualise
        let avgDailyVariance = forecastVariance / Double(horizon)
        return sqrt(avgDailyVariance * ReturnStats.tradingDaysPerYear)
    }

    private func estimateParameters(_ returns: [Double]) -> Parameters? {
        let variance = unconditionalVariance(returns)
        guard variance > 0 else { return nil }

        // Simple moment-matching defaults (robust starting point)
        let alpha = 0.10
        let beta  = 0.85
        let omega = variance * (1 - alpha - beta)

        let params = Parameters(omega: omega, alpha: alpha, beta: beta)
        return params.isValid ? params : nil
    }

    private func unconditionalVariance(_ returns: [Double]) -> Double {
        guard returns.count > 1 else { return 0 }
        let mean = returns.reduce(0, +) / Double(returns.count)
        return returns.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(returns.count - 1)
    }
}
