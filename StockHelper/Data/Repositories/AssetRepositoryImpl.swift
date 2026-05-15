import Foundation
import SwiftData

final class AssetRepositoryImpl: AssetRepository {
    private let provider: any MarketDataProvider
    private let persistence: PersistenceController

    // Cache TTL: 7 days for search results
    private let searchCacheTTL: TimeInterval = 7 * 24 * 3600

    init(provider: any MarketDataProvider, persistence: PersistenceController) {
        self.provider = provider
        self.persistence = persistence
    }

    func search(_ query: String) async throws -> [Asset] {
        // Network fetch, then cache in background
        let assets = try await provider.searchSymbols(query)
        Task { await cacheAssets(assets) }
        return assets
    }

    func fetchQuote(symbol: String) async throws -> Quote {
        try await provider.fetchQuote(symbol: symbol)
    }

    @MainActor
    func saveToWatchlist(_ asset: Asset) async throws {
        guard let ctx = persistence.context else { return }
        let existing = try ctx.fetch(FetchDescriptor<AssetEntity>(
            predicate: #Predicate { $0.symbol == asset.id }
        )).first

        if let existing {
            existing.isWatchlisted = true
            existing.lastUpdated = Date()
        } else {
            let entity = AssetEntity(asset: asset, isWatchlisted: true)
            ctx.insert(entity)
        }
        try ctx.save()
    }

    @MainActor
    func removeFromWatchlist(symbol: String) async throws {
        guard let ctx = persistence.context else { return }
        let matches = try ctx.fetch(FetchDescriptor<AssetEntity>(
            predicate: #Predicate { $0.symbol == symbol }
        ))
        matches.forEach { $0.isWatchlisted = false }
        try ctx.save()
    }

    @MainActor
    func fetchWatchlist() async throws -> [Asset] {
        guard let ctx = persistence.context else { return [] }
        let entities = try ctx.fetch(FetchDescriptor<AssetEntity>(
            predicate: #Predicate { $0.isWatchlisted }
        ))
        return entities.map { $0.toDomain() }
    }

    @MainActor
    func isInWatchlist(symbol: String) async -> Bool {
        guard let ctx = persistence.context else { return false }
        let matches = try? ctx.fetch(FetchDescriptor<AssetEntity>(
            predicate: #Predicate { $0.symbol == symbol && $0.isWatchlisted }
        ))
        return !(matches?.isEmpty ?? true)
    }

    @MainActor
    private func cacheAssets(_ assets: [Asset]) {
        guard let ctx = persistence.context else { return }
        for asset in assets {
            let sym = asset.id
            let existing = try? ctx.fetch(FetchDescriptor<AssetEntity>(
                predicate: #Predicate { $0.symbol == sym }
            )).first
            if existing == nil {
                ctx.insert(AssetEntity(asset: asset))
            }
        }
        try? ctx.save()
    }
}
