import Foundation

enum BollingerBands {
    static func compute(_ values: [Double], period: Int = 20, multiplier: Double = 2.0) -> BollingerResult {
        guard values.count >= period else {
            let nan = Array(repeating: Double.nan, count: values.count)
            return BollingerResult(upper: nan, middle: nan, lower: nan, bandwidth: nan, percentB: nan)
        }

        let middle = SMA.compute(values, period: period)
        var upper = Array(repeating: Double.nan, count: values.count)
        var lower = Array(repeating: Double.nan, count: values.count)
        var bandwidth = Array(repeating: Double.nan, count: values.count)
        var percentB = Array(repeating: Double.nan, count: values.count)

        for i in (period - 1)..<values.count {
            let window = Array(values[(i - period + 1)...i])
            let std = standardDeviation(window)
            let m = middle[i]
            let u = m + multiplier * std
            let l = m - multiplier * std
            upper[i] = u
            lower[i] = l
            bandwidth[i] = m != 0 ? (u - l) / m : Double.nan
            percentB[i] = (u - l) != 0 ? (values[i] - l) / (u - l) : 0.5
        }

        return BollingerResult(upper: upper, middle: middle, lower: lower, bandwidth: bandwidth, percentB: percentB)
    }

    private static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}
