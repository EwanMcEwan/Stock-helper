import Foundation

enum SMA {
    /// Returns an array the same length as `values`.
    /// Leading elements that don't have enough history are `Double.nan`.
    static func compute(_ values: [Double], period: Int) -> [Double] {
        guard period > 0, values.count >= period else {
            return Array(repeating: Double.nan, count: values.count)
        }
        var result = Array(repeating: Double.nan, count: values.count)
        var windowSum = values[0..<period].reduce(0, +)
        result[period - 1] = windowSum / Double(period)
        for i in period..<values.count {
            windowSum += values[i] - values[i - period]
            result[i] = windowSum / Double(period)
        }
        return result
    }
}
