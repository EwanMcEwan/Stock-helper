import Foundation

protocol MarketDataRepository {
    func fetchHistory(
        symbol: String,
        range: DateInterval,
        interval: BarInterval
    ) async throws -> [PriceBar]
}

protocol MarketDataProvider {
    var name: String { get }
    func searchSymbols(_ query: String) async throws -> [Asset]
    func fetchHistory(symbol: String, range: DateInterval, interval: BarInterval) async throws -> [PriceBar]
    func fetchQuote(symbol: String) async throws -> Quote
}
