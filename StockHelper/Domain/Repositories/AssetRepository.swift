import Foundation

protocol AssetRepository {
    func search(_ query: String) async throws -> [Asset]
    func fetchQuote(symbol: String) async throws -> Quote
    func saveToWatchlist(_ asset: Asset) async throws
    func removeFromWatchlist(symbol: String) async throws
    func fetchWatchlist() async throws -> [Asset]
    func isInWatchlist(symbol: String) async -> Bool
}
