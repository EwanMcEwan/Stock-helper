import SwiftUI

struct AssetDetailView: View {
    @StateObject var viewModel: AssetDetailViewModel
    @EnvironmentObject var deps: AppDependencies
    @State private var showForecast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {

                // Range picker
                Picker("Range", selection: Binding(
                    get: { viewModel.selectedRange },
                    set: { viewModel.changeRange($0) }
                )) {
                    ForEach(RangeOption.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                } else if let error = viewModel.error {
                    ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
                        .frame(minHeight: 240)
                } else if !viewModel.bars.isEmpty {
                    // Price change badge
                    if let pctText = viewModel.priceChangeText {
                        HStack {
                            Text(pctText)
                                .font(.headline)
                                .foregroundColor(viewModel.priceChangeIsPositive ? AppTheme.Colors.bullish : AppTheme.Colors.bearish)
                            Text(viewModel.selectedRange.rawValue).font(.caption).foregroundColor(.secondary)
                        }
                    }

                    PriceChartView(bars: viewModel.bars, indicators: viewModel.indicators)
                        .padding(.horizontal)

                    // Technical signals
                    if let indicators = viewModel.indicators, !indicators.signals.isEmpty {
                        technicalSignalsSection(signals: indicators.signals)
                    }
                }

                Divider()

                // Forecast CTA
                Button {
                    showForecast = true
                } label: {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Generate Forecast")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.asset.id)
        .navigationSubtitle(viewModel.asset.name)
        .task { await viewModel.load() }
        .sheet(isPresented: $showForecast) {
            NavigationStack {
                ForecastView(viewModel: deps.makeForecastViewModel(asset: viewModel.asset))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showForecast = false }
                        }
                    }
            }
        }
    }

    private func technicalSignalsSection(signals: [TechnicalSignal]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Technical Signals")
                .font(AppTheme.Font.sectionHeader)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(signals) { signal in
                        SignalCard(signal: signal)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SignalCard: View {
    let signal: TechnicalSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(signal.name).font(.caption).foregroundColor(.secondary)
            Text(signal.value, format: .number.precision(.fractionLength(2)))
                .font(.headline)
                .foregroundColor(AppTheme.Colors.direction(signal.direction))
            Text(signal.description).font(.caption2).foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
        .frame(minWidth: 100)
    }
}
