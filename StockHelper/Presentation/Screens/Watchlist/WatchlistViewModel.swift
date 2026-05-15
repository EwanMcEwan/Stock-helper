import Foundation

@MainActor
final class WatchlistViewModel: ObservableObject {
    @Published var items: [(asset: Asset, quote: Quote?)] = []
    @Published var isRefreshing = false
    @Published var error: String?

    private let persistence: PersistenceController
    private let fetchHistoryUseCase: FetchHistoryUseCase

    init(persistence: PersistenceController, fetchHistoryUseCase: FetchHistoryUseCase) {
        self.persistence = persistence
        self.fetchHistoryUseCase = fetchHistoryUseCase
    }

    func load() async {
        guard let ctx = persistence.context else { return }
        do {
            let entities = try ctx.fetch(.init(predicate: #Predicate<AssetEntity> { $0.isWatchlisted }))
            items = entities.map { (asset: $0.toDomain(), quote: nil) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func remove(at offsets: IndexSet) {
        guard let ctx = persistence.context else { return }
        offsets.forEach { i in
            let sym = items[i].asset.id
            let entities = (try? ctx.fetch(.init(predicate: #Predicate<AssetEntity> { $0.symbol == sym }))) ?? []
            entities.forEach { $0.isWatchlisted = false }
        }
        try? ctx.save()
        items.remove(atOffsets: offsets)
    }

    func refresh() async {
        isRefreshing = true
        await load()
        isRefreshing = false
    }
}
