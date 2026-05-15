import Foundation
import Combine

/// Composition root — single place where concrete types are wired together.
@MainActor
final class AppDependencies: ObservableObject {

    // MARK: - Infrastructure

    private let apiClient: APIClient
    private let rateLimiter: RateLimiter
    private let persistenceController: PersistenceController

    // MARK: - Providers

    private let yahooProvider: YahooFinanceProvider
    private let alphaVantageProvider: AlphaVantageProvider
    private let finnhubProvider: FinnhubProvider
    private let providerRouter: ProviderRouter

    // MARK: - Repositories

    private let assetRepository: AssetRepositoryImpl
    private let marketDataRepository: MarketDataRepositoryImpl

    // MARK: - Use Cases

    private let searchAssetsUseCase: SearchAssetsUseCase
    private let fetchHistoryUseCase: FetchHistoryUseCase
    private let computeIndicatorsUseCase: ComputeIndicatorsUseCase
    private let generateForecastUseCase: GenerateForecastUseCase

    // MARK: - Init

    init() {
        let settings = UserSettings.shared
        apiClient = APIClient()
        rateLimiter = RateLimiter()
        persistenceController = PersistenceController.shared

        yahooProvider = YahooFinanceProvider(client: apiClient, rateLimiter: rateLimiter)
        alphaVantageProvider = AlphaVantageProvider(client: apiClient, rateLimiter: rateLimiter, apiKey: settings.alphaVantageKey)
        finnhubProvider = FinnhubProvider(client: apiClient, rateLimiter: rateLimiter, apiKey: settings.finnhubKey)

        providerRouter = ProviderRouter(providers: [yahooProvider, alphaVantageProvider, finnhubProvider])

        assetRepository = AssetRepositoryImpl(
            provider: providerRouter,
            persistence: persistenceController
        )
        marketDataRepository = MarketDataRepositoryImpl(
            provider: providerRouter,
            persistence: persistenceController
        )

        searchAssetsUseCase = SearchAssetsUseCase(repository: assetRepository)
        fetchHistoryUseCase = FetchHistoryUseCase(repository: marketDataRepository)
        computeIndicatorsUseCase = ComputeIndicatorsUseCase()
        generateForecastUseCase = GenerateForecastUseCase(
            historyUseCase: fetchHistoryUseCase,
            indicatorsUseCase: computeIndicatorsUseCase
        )
    }

    func configure() async {
        await persistenceController.setup()
    }

    // MARK: - ViewModel Factories

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(searchUseCase: searchAssetsUseCase)
    }

    func makeAssetDetailViewModel(asset: Asset) -> AssetDetailViewModel {
        AssetDetailViewModel(
            asset: asset,
            fetchHistoryUseCase: fetchHistoryUseCase,
            computeIndicatorsUseCase: computeIndicatorsUseCase
        )
    }

    func makeForecastViewModel(asset: Asset) -> ForecastViewModel {
        ForecastViewModel(asset: asset, generateForecastUseCase: generateForecastUseCase)
    }

    func makeWatchlistViewModel() -> WatchlistViewModel {
        WatchlistViewModel(
            persistence: persistenceController,
            fetchHistoryUseCase: fetchHistoryUseCase
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel()
    }
}
