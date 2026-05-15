import Foundation
import os.log

private let logger = Logger(subsystem: "com.stockhelper", category: "ProviderRouter")

/// Tries providers in order, rotating on 429 / error.
final class ProviderRouter: MarketDataProvider {
    let name = "Router"
    private let providers: [any MarketDataProvider]

    init(providers: [any MarketDataProvider]) {
        self.providers = providers
    }

    func searchSymbols(_ query: String) async throws -> [Asset] {
        try await withFailover { try await $0.searchSymbols(query) }
    }

    func fetchHistory(symbol: String, range: DateInterval, interval: BarInterval) async throws -> [PriceBar] {
        try await withFailover { try await $0.fetchHistory(symbol: symbol, range: range, interval: interval) }
    }

    func fetchQuote(symbol: String) async throws -> Quote {
        try await withFailover { try await $0.fetchQuote(symbol: symbol) }
    }

    private func withFailover<T>(_ operation: (any MarketDataProvider) async throws -> T) async throws -> T {
        var lastError: Error = APIError.noData
        for provider in providers {
            do {
                let result = try await operation(provider)
                logger.debug("Success via \(provider.name)")
                return result
            } catch APIError.rateLimited {
                logger.warning("\(provider.name) rate limited, trying next provider")
                lastError = APIError.rateLimited
            } catch {
                logger.warning("\(provider.name) failed: \(error.localizedDescription), trying next provider")
                lastError = error
            }
        }
        throw lastError
    }
}
