import Foundation

final class SearchAssetsUseCase {
    private let repository: AssetRepository

    init(repository: AssetRepository) {
        self.repository = repository
    }

    func execute(_ query: String) async throws -> [Asset] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 1 else { return [] }
        return try await repository.search(trimmed)
    }
}
