import Foundation
import CoreML

/// Wraps a Core ML LSTM model that outputs a short-horizon directional bias.
/// The model file (StockLSTM.mlmodel) is expected in Resources/Models/.
/// Falls back to neutral (0.5) if the model is unavailable.
final class LSTMPredictor {
    private var model: MLModel?

    init() {
        loadModel()
    }

    /// Returns a bias in [0, 1] where > 0.5 = bullish, < 0.5 = bearish.
    func predict(features: FeatureVector) -> Double {
        guard let model else { return 0.5 }  // neutral fallback
        do {
            let input = try buildMLInput(features: features)
            let output = try model.prediction(from: input)
            return extractBias(from: output)
        } catch {
            return 0.5
        }
    }

    private func loadModel() {
        guard let url = Bundle.main.url(forResource: "StockLSTM", withExtension: "mlmodelc") else {
            return
        }
        model = try? MLModel(contentsOf: url)
    }

    private func buildMLInput(features: FeatureVector) throws -> MLFeatureProvider {
        // Flatten features into a 1D array for the model's multiArray input
        var flat = features.normalizedReturns
        flat.append(features.rsi)
        flat.append(features.macdHistogram)
        flat.append(features.bollingerPctB)
        flat.append(features.volumeRatio)
        flat.append(features.volatilityRank)

        let arr = try MLMultiArray(shape: [NSNumber(value: flat.count)], dataType: .float32)
        for (i, v) in flat.enumerated() {
            arr[i] = NSNumber(value: v)
        }
        return try MLDictionaryFeatureProvider(dictionary: ["features": MLFeatureValue(multiArray: arr)])
    }

    private func extractBias(from output: MLFeatureProvider) -> Double {
        guard let val = output.featureValue(for: "bias") else { return 0.5 }
        switch val.type {
        case .double: return min(max(val.doubleValue, 0), 1)
        case .multiArray:
            guard let arr = val.multiArrayValue, arr.count > 0 else { return 0.5 }
            return min(max(Double(truncating: arr[0]), 0), 1)
        default: return 0.5
        }
    }
}
