import SwiftUI

struct ConfidenceGaugeView: View {
    let confidence: Double
    let label: String

    private var color: Color {
        switch confidence {
        case 0..<0.35: AppTheme.Colors.confidenceLow
        case 0.35..<0.6: AppTheme.Colors.confidenceMedium
        default: AppTheme.Colors.confidenceHigh
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Gauge(value: confidence, in: 0...1) {
                EmptyView()
            } currentValueLabel: {
                Text("\(Int(confidence * 100))%")
                    .font(.headline)
                    .foregroundColor(color)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(color)

            Text(label)
                .font(AppTheme.Font.statLabel)
                .foregroundColor(.secondary)
        }
    }
}
