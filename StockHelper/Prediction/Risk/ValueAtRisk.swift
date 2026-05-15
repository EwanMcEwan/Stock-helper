import Foundation

enum ValueAtRisk {
    /// Historical simulation VaR at the given confidence level (e.g. 0.95 = 95% VaR).
    /// Returns the loss threshold: P(loss > result) = 1 - confidence.
    static func historical(logReturns: [Double], confidence: Double = 0.95, portfolioValue: Double = 1.0) -> Double {
        guard !logReturns.isEmpty else { return 0 }
        let sorted = logReturns.sorted()
        let idx = Int((1 - confidence) * Double(sorted.count))
        let worstReturn = sorted[max(idx, 0)]
        return portfolioValue * (1 - exp(worstReturn))
    }

    /// Parametric (normal distribution) VaR — faster but assumes normality.
    static func parametric(mean: Double, std: Double, confidence: Double = 0.95, portfolioValue: Double = 1.0) -> Double {
        let z = normalQuantile(confidence)  // e.g. 1.645 for 95%
        let dailyVaR = portfolioValue * (exp(mean - z * std) - 1)
        return abs(dailyVaR)
    }

    /// Inverse normal CDF approximation (Beasley-Springer-Moro).
    private static func normalQuantile(_ p: Double) -> Double {
        switch p {
        case 0.99: return 2.326
        case 0.975: return 1.960
        case 0.95: return 1.645
        case 0.90: return 1.282
        default:
            // Rational approximation for other values
            let a = [2.515517, 0.802853, 0.010328]
            let b = [1.432788, 0.189269, 0.001308]
            let t = sqrt(-2 * log(1 - p))
            let num = a[0] + a[1] * t + a[2] * t * t
            let den = 1 + b[0] * t + b[1] * t * t + b[2] * t * t * t
            return t - num / den
        }
    }
}
