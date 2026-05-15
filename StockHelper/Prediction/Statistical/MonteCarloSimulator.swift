import Foundation

/// Geometric Brownian Motion Monte Carlo simulator.
final class MonteCarloSimulator {
    private var rng = SystemRandomNumberGenerator()

    /// Returns (paths, bands) where each path has `days+1` elements (day 0 = startPrice).
    func simulate(
        startPrice: Double,
        drift: Double,
        volatility: Double,
        days: Int,
        simulations: Int
    ) -> (paths: [[Double]], bands: PercentileBands) {
        let dt = 1.0 / ReturnStats.tradingDaysPerYear
        let sqrtDt = sqrt(dt)
        let drift_dt = (drift - 0.5 * volatility * volatility) * dt

        var paths = [[Double]](repeating: [Double](repeating: 0, count: days + 1), count: simulations)

        for s in 0..<simulations {
            paths[s][0] = startPrice
            for d in 1...days {
                let z = boxMullerNormal()
                let logReturn = drift_dt + volatility * sqrtDt * z
                paths[s][d] = paths[s][d - 1] * exp(logReturn)
            }
        }

        let bands = computeBands(paths: paths, days: days)
        return (paths, bands)
    }

    private func computeBands(paths: [[Double]], days: Int) -> PercentileBands {
        var p5  = [Double](repeating: 0, count: days + 1)
        var p25 = [Double](repeating: 0, count: days + 1)
        var p75 = [Double](repeating: 0, count: days + 1)
        var p95 = [Double](repeating: 0, count: days + 1)

        let n = paths.count
        for d in 0...(days) {
            var prices = paths.map { $0[d] }.sorted()
            p5[d]  = prices[Int(Double(n - 1) * 0.05)]
            p25[d] = prices[Int(Double(n - 1) * 0.25)]
            p75[d] = prices[Int(Double(n - 1) * 0.75)]
            p95[d] = prices[Int(Double(n - 1) * 0.95)]
        }

        return PercentileBands(p5: p5, p25: p25, p75: p75, p95: p95)
    }

    /// Box-Muller transform for standard normal samples.
    private func boxMullerNormal() -> Double {
        var u1: Double, u2: Double
        repeat { u1 = Double.random(in: 0..<1) } while u1 == 0
        u2 = Double.random(in: 0..<1)
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }
}
