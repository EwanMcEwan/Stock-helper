import SwiftUI

struct ForecastView: View {
    @StateObject var viewModel: ForecastViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {

                // Horizon picker
                VStack(alignment: .leading) {
                    Text("Forecast Horizon")
                        .font(AppTheme.Font.sectionHeader)
                    HStack {
                        ForEach(viewModel.horizonOptions, id: \.self) { days in
                            Button("\(days)d") {
                                viewModel.changeHorizon(days)
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.selectedHorizon == days ? .accentColor : .secondary)
                        }
                    }
                }
                .padding(.horizontal)

                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Running 10,000 simulations…")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.error {
                    ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
                } else if let forecast = viewModel.forecast {
                    forecastContent(forecast)
                } else {
                    ContentUnavailableView(
                        "No Forecast Yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Select a horizon above to generate a forecast.")
                    )
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Forecast — \(viewModel.asset.id)")
        .task { await viewModel.generate() }
    }

    // MARK: - Forecast content

    private func forecastContent(_ forecast: Forecast) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {

            // Confidence + volatility summary
            HStack {
                ConfidenceGaugeView(
                    confidence: forecast.confidence,
                    label: "Model Confidence"
                )
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Annual Volatility")
                        .font(AppTheme.Font.statLabel)
                        .foregroundColor(.secondary)
                    Text("\(forecast.volatilityAnnualised * 100, specifier: "%.1f")%")
                        .font(.headline)
                }
            }
            .padding(.horizontal)

            ProbabilityConeView(forecast: forecast)
                .padding(.horizontal)

            probabilitiesSection(forecast.probabilities)

            plainEnglishSummary(forecast)

            disclaimerSection(forecast.disclaimer)
        }
    }

    private func probabilitiesSection(_ probs: [Probability]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Outcome Probabilities").font(AppTheme.Font.sectionHeader)

            ForEach(probs, id: \.description) { prob in
                HStack {
                    Text(prob.description)
                    Spacer()
                    Text(prob.percent)
                        .fontWeight(.semibold)
                        .foregroundColor(prob.value > 0.5 ? AppTheme.Colors.bullish : AppTheme.Colors.bearish)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .padding(.horizontal)
    }

    private func plainEnglishSummary(_ forecast: Forecast) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What This Means").font(AppTheme.Font.sectionHeader)
            Text(buildSummary(forecast))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .cardStyle()
        .padding(.horizontal)
    }

    private func buildSummary(_ f: Forecast) -> String {
        let upProb = f.probabilities.first { $0.description.contains("rises ≥ 10%") }?.value ?? 0
        let downProb = f.probabilities.first { $0.description.contains("falls ≥ 10%") }?.value ?? 0
        let volStr = String(format: "%.0f%%", f.volatilityAnnualised * 100)
        return """
        Over the next \(f.horizonDays) trading days, \(f.asset.id) shows annualised volatility of ~\(volStr). \
        The model estimates a \(Int(upProb * 100))% chance of gaining 10%+ and a \(Int(downProb * 100))% chance of falling 10%+. \
        Confidence is \(f.confidenceLabel.lowercased()) — longer horizons and high volatility reduce forecast reliability.
        """
    }

    private func disclaimerSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Important Disclaimer", systemImage: "exclamationmark.shield.fill")
                .font(.caption)
                .foregroundColor(.orange)
            Text(text)
                .disclaimerStyle()
        }
        .padding()
        .background(Color.orange.opacity(0.07))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
