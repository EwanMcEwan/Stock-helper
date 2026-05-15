import Foundation
import SwiftData

final class MarketDataRepositoryImpl: MarketDataRepository {
    private let provider: any MarketDataProvider
    private let persistence: PersistenceController

    // Cache TTLs
    private let eodCacheTTL: TimeInterval = 24 * 3600
    private let intradayCacheTTL: TimeInterval = 60

    init(provider: any MarketDataProvider, persistence: PersistenceController) {
        self.provider = provider
        self.persistence = persistence
    }

    func fetchHistory(symbol: String, range: DateInterval, interval: BarInterval) async throws -> [PriceBar] {
        // Try cache first for EOD data
        if !interval.isIntraday, let cached = await cachedBars(symbol: symbol, range: range, interval: interval) {
            return cached
        }
        let bars = try await provider.fetchHistory(symbol: symbol, range: range, interval: interval)
        Task { await cacheBars(bars, symbol: symbol, interval: interval) }
        return bars
    }

    @MainActor
    private func cachedBars(symbol: String, range: DateInterval, interval: BarInterval) -> [PriceBar]? {
        guard let ctx = persistence.context else { return nil }
        let sym = symbol
        let iv = interval.rawValue
        let start = range.start
        let end = range.end
        let entities = try? ctx.fetch(FetchDescriptor<PriceBarEntity>(
            predicate: #Predicate {
                $0.symbol == sym &&
                $0.intervalRaw == iv &&
                $0.date >= start &&
                $0.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        ))
        guard let entities, !entities.isEmpty else { return nil }
        return entities.map { $0.toDomain() }
    }

    @MainActor
    private func cacheBars(_ bars: [PriceBar], symbol: String, interval: BarInterval) {
        guard let ctx = persistence.context else { return }
        bars.forEach { bar in
            let entity = PriceBarEntity(symbol: symbol, bar: bar, interval: interval)
            ctx.insert(entity)
        }
        try? ctx.save()
    }
}
