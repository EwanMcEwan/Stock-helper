import XCTest
@testable import StockHelper

final class IndicatorsTests: XCTestCase {

    // MARK: - SMA

    func testSMALeadingNaN() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let sma = SMA.compute(values, period: 3)
        XCTAssertTrue(sma[0].isNaN)
        XCTAssertTrue(sma[1].isNaN)
        XCTAssertEqual(sma[2], 2.0, accuracy: 1e-10)
        XCTAssertEqual(sma[3], 3.0, accuracy: 1e-10)
        XCTAssertEqual(sma[4], 4.0, accuracy: 1e-10)
    }

    func testSMALength() {
        let values = Array(1...20).map(Double.init)
        let sma = SMA.compute(values, period: 5)
        XCTAssertEqual(sma.count, values.count)
    }

    func testSMASinglePeriod() {
        let values = [10.0, 20.0, 30.0]
        let sma = SMA.compute(values, period: 1)
        XCTAssertEqual(sma, values)
    }

    // MARK: - EMA

    func testEMALeadingNaN() {
        let values = Array(repeating: 10.0, count: 10)
        let ema = EMA.compute(values, period: 5)
        XCTAssertTrue(ema[0].isNaN)
        XCTAssertTrue(ema[3].isNaN)
        XCTAssertFalse(ema[4].isNaN)
    }

    func testEMAConstantSeriesEqualsValue() {
        let value = 42.0
        let values = Array(repeating: value, count: 30)
        let ema = EMA.compute(values, period: 10)
        for i in 9..<30 {
            XCTAssertEqual(ema[i], value, accuracy: 1e-8)
        }
    }

    // MARK: - RSI

    func testRSIBoundsAllUpMoves() {
        var prices = [100.0]
        for _ in 0..<20 { prices.append(prices.last! + 1.0) }
        let rsi = RSI.compute(prices, period: 14)
        let validValues = rsi.filter { !$0.isNaN }
        for v in validValues {
            XCTAssertGreaterThanOrEqual(v, 0)
            XCTAssertLessThanOrEqual(v, 100)
        }
        // All-up RSI should be near 100
        XCTAssertGreaterThan(validValues.last ?? 0, 90)
    }

    func testRSIAllDownMovesNearZero() {
        var prices = [100.0]
        for _ in 0..<20 { prices.append(prices.last! - 1.0) }
        let rsi = RSI.compute(prices, period: 14)
        let validValues = rsi.filter { !$0.isNaN }
        XCTAssertLessThan(validValues.last ?? 100, 10)
    }

    // MARK: - Bollinger Bands

    func testBollingerBandsUpperAboveLower() {
        let values = (1...50).map { Double($0) + Double.random(in: -2...2) }
        let bb = BollingerBands.compute(values, period: 20, multiplier: 2.0)
        for i in 19..<50 {
            XCTAssertGreaterThan(bb.upper[i], bb.lower[i])
            XCTAssertGreaterThan(bb.upper[i], bb.middle[i])
            XCTAssertLessThan(bb.lower[i], bb.middle[i])
        }
    }

    func testBollingerPercentBMiddle() {
        // When price equals the middle band, %B = 0.5
        let values = Array(repeating: 100.0, count: 30)
        let bb = BollingerBands.compute(values, period: 20, multiplier: 2.0)
        // Flat series: upper = lower = middle (zero width), so percentB defaults to 0.5
        XCTAssertEqual(bb.percentB[29], 0.5, accuracy: 1e-10)
    }

    // MARK: - MACD

    func testMACDHistogramLength() {
        let values = (1...60).map { Double($0) }
        let macd = MACD.compute(values)
        XCTAssertEqual(macd.macdLine.count, values.count)
        XCTAssertEqual(macd.signalLine.count, values.count)
        XCTAssertEqual(macd.histogram.count, values.count)
    }

    func testMACDHistogramEqualsMACDMinusSignal() {
        let values = (1...60).map { Double($0) + Double.random(in: -5...5) }
        let macd = MACD.compute(values)
        for i in 0..<values.count {
            if !macd.macdLine[i].isNaN && !macd.signalLine[i].isNaN {
                XCTAssertEqual(macd.histogram[i], macd.macdLine[i] - macd.signalLine[i], accuracy: 1e-10)
            }
        }
    }
}
