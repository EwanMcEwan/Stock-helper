import XCTest
@testable import StockHelper

final class MonteCarloTests: XCTestCase {
    private let simulator = MonteCarloSimulator()

    func testPathCountAndLength() {
        let (paths, _) = simulator.simulate(startPrice: 100, drift: 0.08, volatility: 0.20, days: 30, simulations: 100)
        XCTAssertEqual(paths.count, 100)
        XCTAssertEqual(paths.first?.count, 31)  // day 0 + 30 days
    }

    func testAllPathsStartAtStartPrice() {
        let (paths, _) = simulator.simulate(startPrice: 150, drift: 0, volatility: 0.20, days: 5, simulations: 50)
        for path in paths {
            XCTAssertEqual(path[0], 150, accuracy: 1e-10)
        }
    }

    func testAllPricesPositive() {
        let (paths, _) = simulator.simulate(startPrice: 10, drift: -0.50, volatility: 0.80, days: 252, simulations: 500)
        for path in paths {
            for price in path {
                XCTAssertGreaterThan(price, 0, "GBM prices must always be positive")
            }
        }
    }

    func testBandOrdering() {
        let (_, bands) = simulator.simulate(startPrice: 100, drift: 0, volatility: 0.20, days: 30, simulations: 1000)
        for d in 0...30 {
            XCTAssertLessThanOrEqual(bands.p5[d], bands.p25[d])
            XCTAssertLessThanOrEqual(bands.p25[d], bands.p75[d])
            XCTAssertLessThanOrEqual(bands.p75[d], bands.p95[d])
        }
    }

    func testZeroVolatilityDeterministicPath() {
        // σ=0: each step is exactly e^(μ·dt)
        let startPrice = 100.0
        let drift = 0.10
        let days = 10
        let (paths, _) = simulator.simulate(startPrice: startPrice, drift: drift, volatility: 1e-10, days: days, simulations: 10)
        let dt = 1.0 / 252.0
        let expectedFactor = exp((drift - 0.5 * 1e-10 * 1e-10) * dt)
        for path in paths {
            for d in 1...days {
                let expected = startPrice * pow(expectedFactor, Double(d))
                XCTAssertEqual(path[d], expected, accuracy: expected * 0.01)
            }
        }
    }
}
