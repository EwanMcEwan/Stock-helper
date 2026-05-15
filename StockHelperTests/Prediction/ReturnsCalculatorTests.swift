import XCTest
@testable import StockHelper

final class ReturnsCalculatorTests: XCTestCase {
    private let calculator = ReturnsCalculator()

    func testLogReturnCount() {
        let prices = Array(1...20).map(Double.init)
        let stats = calculator.compute(prices)
        XCTAssertEqual(stats.logReturns.count, prices.count - 1)
    }

    func testConstantPriceZeroReturns() {
        let prices = Array(repeating: 50.0, count: 30)
        let stats = calculator.compute(prices)
        XCTAssertEqual(stats.mean, 0, accuracy: 1e-12)
        XCTAssertEqual(stats.annualisedVolatility, 0, accuracy: 1e-8)
    }

    func testKnownLogReturn() {
        // price doubles: log(2/1) = ln(2)
        let prices = [1.0, 2.0]
        let stats = calculator.compute(prices)
        XCTAssertEqual(stats.logReturns[0], log(2), accuracy: 1e-12)
    }

    func testAnnualisedVolatilityScale() {
        // Generate returns with known daily std
        let dailyStd = 0.01
        var prices = [100.0]
        for i in 1...300 {
            prices.append(prices[i - 1] * exp(dailyStd * (Double.random(in: -1...1))))
        }
        let stats = calculator.compute(prices)
        let expectedAnnVol = dailyStd * sqrt(252)
        // Rough bound: within 50% of expected (randomness)
        XCTAssertGreaterThan(stats.annualisedVolatility, expectedAnnVol * 0.5)
        XCTAssertLessThan(stats.annualisedVolatility, expectedAnnVol * 1.5)
    }

    func testSinglePriceReturnsEmpty() {
        let stats = calculator.compute([100.0])
        XCTAssertEqual(stats.logReturns.count, 0)
        XCTAssertEqual(stats.mean, 0)
    }
}
