import Foundation

struct EnsembleResult {
    let adjustedMedian: [Double]?
    let lstmBias: Double    // 0...1, 0.5 = neutral
    let lstmWeight: Double  // how much the LSTM nudged the ensemble
}

/// Blends Monte Carlo paths with an LSTM directional signal.
/// The LSTM is deliberately low-weight — it nudges, never dominates.
final class EnsembleCombiner {
    private let lstm = LSTMPredictor()
    private let maxLSTMWeight = 0.15  // LSTM never exceeds 15% influence

    func combine(
        monteCarloPaths: [[Double]],
        indicators: IndicatorResult,
        startPrice: Double,
        horizon: Int
    ) -> EnsembleResult {
        guard let features = buildLatestFeature(indicators: indicators, startPrice: startPrice) else {
            return EnsembleResult(adjustedMedian: nil, lstmBias: 0.5, lstmWeight: 0)
        }

        let bias = lstm.predict(features: features)
        guard abs(bias - 0.5) > 0.05 else {
            // Bias too close to neutral — skip adjustment
            return EnsembleResult(adjustedMedian: nil, lstmBias: bias, lstmWeight: 0)
        }

        let nudge = (bias - 0.5) * maxLSTMWeight * 2  // maps [0..1] → [-15%..+15%]
        let adjustedMedian = computeAdjustedMedian(paths: monteCarloPaths, horizon: horizon, nudge: nudge)

        return EnsembleResult(adjustedMedian: adjustedMedian, lstmBias: bias, lstmWeight: abs(nudge))
    }

    private func buildLatestFeature(indicators: IndicatorResult, startPrice: Double) -> FeatureVector? {
        let rsi = indicators.rsi14.last ?? Double.nan
        guard !rsi.isNaN else { return nil }

        // Minimal feature for LSTM when full bar history isn't available here
        return FeatureVector(
            normalizedReturns: Array(repeating: 0, count: FeatureEngineering.sequenceLength),
            rsi: rsi / 100.0,
            macdHistogram: indicators.macd.histogram.last.flatMap { $0.isNaN ? nil : $0 } ?? 0,
            bollingerPctB: indicators.bollingerBands.percentB.last.flatMap { $0.isNaN ? nil : $0 } ?? 0.5,
            volumeRatio: 0.5,
            volatilityRank: 0.5
        )
    }

    private func computeAdjustedMedian(paths: [[Double]], horizon: Int, nudge: Double) -> [Double] {
        let dayCount = (paths.first?.count ?? 0)
        return (0..<dayCount).map { day in
            let values = paths.map { $0[day] }.sorted()
            let median = values[values.count / 2]
            // Linear ramp: nudge is full strength by end of horizon
            let rampFactor = day == 0 ? 0 : Double(day) / Double(max(horizon, 1))
            return median * (1 + nudge * rampFactor)
        }
    }
}
