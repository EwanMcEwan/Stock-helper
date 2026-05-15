import Foundation

enum BarInterval: String, CaseIterable {
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case oneHour = "1h"
    case oneDay = "1d"
    case oneWeek = "1wk"
    case oneMonth = "1mo"

    var isIntraday: Bool {
        switch self {
        case .oneMinute, .fiveMinutes, .fifteenMinutes, .oneHour: true
        default: false
        }
    }
}

struct PriceBar: Identifiable {
    let id: UUID
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let adjustedClose: Double?

    init(date: Date, open: Double, high: Double, low: Double,
         close: Double, volume: Double, adjustedClose: Double? = nil) {
        self.id = UUID()
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.adjustedClose = adjustedClose
    }

    var effectiveClose: Double { adjustedClose ?? close }
    var bodyRange: Double { abs(close - open) }
    var totalRange: Double { high - low }
    var isBullish: Bool { close >= open }
}

struct Quote {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Double
    let marketCap: Double?
    let timestamp: Date

    var isPositive: Bool { change >= 0 }
}
