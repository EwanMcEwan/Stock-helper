import XCTest
@testable import StockHelper

// MARK: - Mock providers

final class SuccessProvider: MarketDataProvider {
    let name: String
    var callCount = 0

    init(name: String) { self.name = name }

    func searchSymbols(_ query: String) async throws -> [Asset] {
        callCount += 1
        return [Asset(id: "MOCK", name: "Mock Corp", exchange: "NYSE", kind: .stock, currency: "USD", description: nil)]
    }

    func fetchHistory(symbol: String, range: DateInterval, interval: BarInterval) async throws -> [PriceBar] {
        callCount += 1
        return []
    }

    func fetchQuote(symbol: String) async throws -> Quote {
        callCount += 1
        return Quote(symbol: symbol, price: 100, change: 1, changePercent: 1, volume: 1000, marketCap: nil, timestamp: Date())
    }
}

final class FailingProvider: MarketDataProvider {
    let name: String
    var callCount = 0
    let error: Error

    init(name: String, error: Error = APIError.rateLimited) {
        self.name = name
        self.error = error
    }

    func searchSymbols(_ query: String) async throws -> [Asset] {
        callCount += 1; throw error
    }
    func fetchHistory(symbol: String, range: DateInterval, interval: BarInterval) async throws -> [PriceBar] {
        callCount += 1; throw error
    }
    func fetchQuote(symbol: String) async throws -> Quote {
        callCount += 1; throw error
    }
}

// MARK: - Tests

final class ProviderRouterTests: XCTestCase {

    func testUsesFirstProviderOnSuccess() async throws {
        let p1 = SuccessProvider(name: "P1")
        let p2 = SuccessProvider(name: "P2")
        let router = ProviderRouter(providers: [p1, p2])
        _ = try await router.searchSymbols("AAPL")
        XCTAssertEqual(p1.callCount, 1)
        XCTAssertEqual(p2.callCount, 0)
    }

    func testFallsOverToSecondProviderOnRateLimit() async throws {
        let p1 = FailingProvider(name: "P1", error: APIError.rateLimited)
        let p2 = SuccessProvider(name: "P2")
        let router = ProviderRouter(providers: [p1, p2])
        let results = try await router.searchSymbols("AAPL")
        XCTAssertEqual(p1.callCount, 1)
        XCTAssertEqual(p2.callCount, 1)
        XCTAssertFalse(results.isEmpty)
    }

    func testThrowsWhenAllProvidersFail() async {
        let p1 = FailingProvider(name: "P1")
        let p2 = FailingProvider(name: "P2")
        let router = ProviderRouter(providers: [p1, p2])
        do {
            _ = try await router.searchSymbols("AAPL")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(p1.callCount, 1)
            XCTAssertEqual(p2.callCount, 1)
        }
    }
}
