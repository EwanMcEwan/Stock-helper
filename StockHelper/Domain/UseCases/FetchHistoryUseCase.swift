import Foundation

final class FetchHistoryUseCase {
    private let repository: MarketDataRepository

    init(repository: MarketDataRepository) {
        self.repository = repository
    }

    func execute(
        symbol: String,
        range: DateInterval,
        interval: BarInterval = .oneDay
    ) async throws -> [PriceBar] {
        let bars = try await repository.fetchHistory(symbol: symbol, range: range, interval: interval)
        return bars.sorted { $0.date < $1.date }
    }

    /// Convenience: fetch N trading days of daily data ending today.
    func executeDays(_ days: Int, symbol: String) async throws -> [PriceBar] {
        let end = Date()
        // Add calendar buffer for weekends/holidays
        let start = Calendar.current.date(byAdding: .day, value: -Int(Double(days) * 1.5), to: end)!
        let range = DateInterval(start: start, end: end)
        let bars = try await execute(symbol: symbol, range: range, interval: .oneDay)
        return Array(bars.suffix(days))
    }
}
