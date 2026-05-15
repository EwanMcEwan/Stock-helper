import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Asset] = []
    @Published var isSearching = false
    @Published var error: String?

    private let searchUseCase: SearchAssetsUseCase
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(searchUseCase: SearchAssetsUseCase) {
        self.searchUseCase = searchUseCase
        setupQueryObserver()
    }

    private func setupQueryObserver() {
        $query
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] q in
                self?.performSearch(query: q)
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else {
            results = []
            isSearching = false
            return
        }

        isSearching = true
        error = nil

        searchTask = Task {
            do {
                let assets = try await searchUseCase.execute(query)
                guard !Task.isCancelled else { return }
                results = assets
            } catch is CancellationError {
                // ignored
            } catch {
                self.error = error.localizedDescription
                results = []
            }
            isSearching = false
        }
    }

    func clearSearch() {
        query = ""
        results = []
        error = nil
    }
}
