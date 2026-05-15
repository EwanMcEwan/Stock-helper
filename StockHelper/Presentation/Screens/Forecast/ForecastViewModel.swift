import Foundation

@MainActor
final class ForecastViewModel: ObservableObject {
    let asset: Asset
    @Published var forecast: Forecast?
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedHorizon: Int = 30

    let horizonOptions = [7, 14, 30, 60, 90]

    private let generateForecastUseCase: GenerateForecastUseCase

    init(asset: Asset, generateForecastUseCase: GenerateForecastUseCase) {
        self.asset = asset
        self.generateForecastUseCase = generateForecastUseCase
    }

    func generate() async {
        isLoading = true
        error = nil
        forecast = nil
        do {
            forecast = try await generateForecastUseCase.execute(asset: asset, horizonDays: selectedHorizon)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func changeHorizon(_ days: Int) {
        selectedHorizon = days
        Task { await generate() }
    }
}
