import Foundation

final class GenerateForecastUseCase {
    private let historyUseCase: FetchHistoryUseCase
    private let indicatorsUseCase: ComputeIndicatorsUseCase
    private let calculator = ReturnsCalculator()
    private let garch = GARCHModel()
    private let monteCarlo = MonteCarloSimulator()
    private let ensemble = EnsembleCombiner()

    init(historyUseCase: FetchHistoryUseCase, indicatorsUseCase: ComputeIndicatorsUseCase) {
        self.historyUseCase = historyUseCase
        self.indicatorsUseCase = indicatorsUseCase
    }

    func execute(asset: Asset, horizonDays: Int) async throws -> Forecast {
        // Need at least 252 trading days (1 year) for reliable stats
        let bars = try await historyUseCase.executeDays(max(horizonDays * 5, 252), symbol: asset.id)

        guard bars.count >= 30 else {
            throw ForecastError.insufficientData(available: bars.count, required: 30)
        }

        let closes = bars.map(\.effectiveClose)
        let stats = calculator.compute(closes)
        let garchVol = garch.forecastVolatility(logReturns: stats.logReturns, horizon: horizonDays)
        let effectiveVol = garchVol ?? stats.annualisedVolatility

        let (paths, bands) = monteCarlo.simulate(
            startPrice: closes.last!,
            drift: stats.annualisedDrift,
            volatility: effectiveVol,
            days: horizonDays,
            simulations: 10_000
        )

        let medianPath = computePercentilePath(paths, percentile: 0.50)
        let indicators = indicatorsUseCase.execute(bars: bars)

        let ensembleResult = ensemble.combine(
            monteCarloPaths: paths,
            indicators: indicators,
            startPrice: closes.last!,
            horizon: horizonDays
        )

        let probabilities = buildProbabilities(
            paths: paths,
            startPrice: closes.last!,
            thresholds: [0.05, 0.10, 0.20, -0.05, -0.10, -0.20]
        )

        let confidence = computeConfidence(
            dataCount: bars.count,
            horizon: horizonDays,
            volatility: effectiveVol
        )

        return Forecast(
            asset: asset,
            generatedAt: Date(),
            horizonDays: horizonDays,
            startPrice: closes.last!,
            medianPath: ensembleResult.adjustedMedian ?? medianPath,
            bands: bands,
            probabilities: probabilities,
            confidence: confidence,
            volatilityAnnualised: effectiveVol,
            disclaimer: Forecast.standardDisclaimer
        )
    }

    // MARK: - Private helpers

    private func computePercentilePath(_ paths: [[Double]], percentile: Double) -> [Double] {
        guard let first = paths.first else { return [] }
        return (0..<first.count).map { day in
            let values = paths.map { $0[day] }.sorted()
            let idx = Int(Double(values.count - 1) * percentile)
            return values[idx]
        }
    }

    private func buildProbabilities(paths: [[Double]], startPrice: Double, thresholds: [Double]) -> [Probability] {
        let endPrices = paths.compactMap { $0.last }
        guard !endPrices.isEmpty else { return [] }

        return thresholds.map { threshold in
            let count: Int
            let description: String
            if threshold >= 0 {
                count = endPrices.filter { ($0 - startPrice) / startPrice >= threshold }.count
                description = String(format: "Price rises ≥ %.0f%%", threshold * 100)
            } else {
                count = endPrices.filter { ($0 - startPrice) / startPrice <= threshold }.count
                description = String(format: "Price falls ≥ %.0f%%", abs(threshold) * 100)
            }
            return Probability(description: description, value: Double(count) / Double(endPrices.count))
        }
    }

    private func computeConfidence(dataCount: Int, horizon: Int, volatility: Double) -> Double {
        var confidence = 1.0
        // Penalise for short history
        if dataCount < 252 { confidence *= Double(dataCount) / 252.0 }
        // Penalise for long horizon
        let horizonPenalty = max(0, 1.0 - Double(horizon) / 365.0)
        confidence *= horizonPenalty
        // Penalise for extreme volatility (>80% annualised)
        if volatility > 0.80 { confidence *= 0.80 / volatility }
        return min(max(confidence, 0.05), 0.85)  // never claim >85% confidence
    }
}

enum ForecastError: LocalizedError {
    case insufficientData(available: Int, required: Int)

    var errorDescription: String? {
        switch self {
        case .insufficientData(let available, let required):
            "Need at least \(required) price bars to generate a forecast (have \(available))."
        }
    }
}
