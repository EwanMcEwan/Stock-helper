import Foundation
import SwiftData

@Model
final class PriceBarEntity {
    var symbol: String
    var date: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double
    var adjustedClose: Double?
    var intervalRaw: String

    init(symbol: String, bar: PriceBar, interval: BarInterval) {
        self.symbol = symbol
        self.date = bar.date
        self.open = bar.open
        self.high = bar.high
        self.low = bar.low
        self.close = bar.close
        self.volume = bar.volume
        self.adjustedClose = bar.adjustedClose
        self.intervalRaw = interval.rawValue
    }

    func toDomain() -> PriceBar {
        PriceBar(
            date: date,
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume,
            adjustedClose: adjustedClose
        )
    }
}
