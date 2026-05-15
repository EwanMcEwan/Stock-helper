import Foundation

enum RangeOption: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case twoYears = "2Y"
    case fiveYears = "5Y"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 252
        case .twoYears: return 504
        case .fiveYears: return 1260
        }
    }
}

@MainActor
final class AssetDetailViewModel: ObservableObject {
    let asset: Asset
    @Published var bars: [PriceBar] = []
    @Published var indicators: IndicatorResult?
    @Published var quote: Quote?
    @Published var selectedRange: RangeOption = .sixMonths
    @Published var isLoading = false
    @Published var error: String?

    private let fetchHistoryUseCase: FetchHistoryUseCase
    private let computeIndicatorsUseCase: ComputeIndicatorsUseCase

    init(asset: Asset, fetchHistoryUseCase: FetchHistoryUseCase, computeIndicatorsUseCase: ComputeIndicatorsUseCase) {
        self.asset = asset
        self.fetchHistoryUseCase = fetchHistoryUseCase
        self.computeIndicatorsUseCase = computeIndicatorsUseCase
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            bars = try await fetchHistoryUseCase.executeDays(selectedRange.days, symbol: asset.id)
            indicators = bars.isEmpty ? nil : computeIndicatorsUseCase.execute(bars: bars)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func changeRange(_ range: RangeOption) {
        selectedRange = range
        Task { await load() }
    }

    var priceChangeText: String? {
        guard let first = bars.first?.effectiveClose, let last = bars.last?.effectiveClose, first > 0 else { return nil }
        let pct = (last - first) / first * 100
        return String(format: "%+.2f%%", pct)
    }

    var priceChangeIsPositive: Bool {
        guard let first = bars.first?.effectiveClose, let last = bars.last?.effectiveClose else { return true }
        return last >= first
    }
}
