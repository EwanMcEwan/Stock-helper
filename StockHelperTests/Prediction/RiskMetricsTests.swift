import XCTest
@testable import StockHelper

final class RiskMetricsTests: XCTestCase {

    // MARK: - VaR

    func testHistoricalVaRPositive() {
        let returns = (0..<252).map { _ in Double.random(in: -0.05...0.05) }
        let var95 = ValueAtRisk.historical(logReturns: returns, confidence: 0.95)
        XCTAssertGreaterThanOrEqual(var95, 0, "VaR is expressed as a positive loss figure")
    }

    func testVaREmptyReturns() {
        XCTAssertEqual(ValueAtRisk.historical(logReturns: []), 0)
    }

    func testParametricVaRHigherThanZero() {
        let var95 = ValueAtRisk.parametric(mean: 0, std: 0.01, confidence: 0.95)
        XCTAssertGreaterThan(var95, 0)
    }

    // MARK: - Sharpe

    func testSharpeAllPositiveReturns() {
        let returns = Array(repeating: 0.002, count: 252)  // consistent positive daily return
        let sharpe = SharpeRatio.compute(logReturns: returns, riskFreeRate: 0)
        XCTAssertGreaterThan(sharpe, 0)
    }

    func testSharpeZeroVolatilityEdgeCase() {
        let returns = Array(repeating: 0.0, count: 252)
        let sharpe = SharpeRatio.compute(logReturns: returns, riskFreeRate: 0.05)
        XCTAssertEqual(sharpe, 0)
    }

    func testSortinoPenalisesDownside() {
        let mixedReturns = Array(repeating: 0.001, count: 200) + Array(repeating: -0.05, count: 52)
        let sharpe  = SharpeRatio.compute(logReturns: mixedReturns)
        let sortino = SharpeRatio.sortino(logReturns: mixedReturns)
        // Sortino should differ from Sharpe when there's asymmetric downside
        XCTAssertNotEqual(sharpe, sortino, accuracy: 0.01)
    }

    // MARK: - MaxDrawdown

    func testMaxDrawdownMonotonicUp() {
        let prices = Array(stride(from: 1.0, through: 100.0, by: 1.0))
        let result = MaxDrawdown.compute(prices: prices)
        XCTAssertEqual(result.maxDrawdown, 0, accuracy: 1e-10)
    }

    func testMaxDrawdownMonotonicDown() {
        let prices = Array(stride(from: 100.0, through: 1.0, by: -1.0))
        let result = MaxDrawdown.compute(prices: prices)
        XCTAssertLessThan(result.maxDrawdown, 0)
    }

    func testMaxDrawdownKnownValue() {
        // Prices go 100 → 50 → 80: max drawdown = (50-100)/100 = -50%
        let prices = [100.0, 80.0, 50.0, 60.0, 80.0]
        let result = MaxDrawdown.compute(prices: prices)
        XCTAssertEqual(result.maxDrawdown, -0.5, accuracy: 1e-10)
    }
}
