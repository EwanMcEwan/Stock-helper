import Foundation

enum EMA {
    /// Exponential Moving Average using the standard smoothing factor k = 2/(period+1).
    static func compute(_ values: [Double], period: Int) -> [Double] {
        guard period > 0, !values.isEmpty else { return [] }
        var result = Array(repeating: Double.nan, count: values.count)
        let k = 2.0 / Double(period + 1)

        // Seed with SMA of first `period` values
        guard values.count >= period else { return result }
        let seed = values[0..<period].reduce(0, +) / Double(period)
        result[period - 1] = seed

        for i in period..<values.count {
            result[i] = values[i] * k + result[i - 1] * (1 - k)
        }
        return result
    }
}
