import SwiftUI
import Charts

struct ProbabilityConeView: View {
    let forecast: Forecast

    private var dayIndices: [Int] { Array(0...forecast.horizonDays) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Price Probability Cone")
                .font(AppTheme.Font.sectionHeader)

            Chart {
                // 5–95 percentile band
                ForEach(dayIndices, id: \.self) { d in
                    AreaMark(
                        x: .value("Day", d),
                        yStart: .value("P5", forecast.bands.p5[d]),
                        yEnd: .value("P95", forecast.bands.p95[d])
                    )
                    .foregroundStyle(AppTheme.Colors.cone95)
                }

                // 25–75 percentile band
                ForEach(dayIndices, id: \.self) { d in
                    AreaMark(
                        x: .value("Day", d),
                        yStart: .value("P25", forecast.bands.p25[d]),
                        yEnd: .value("P75", forecast.bands.p75[d])
                    )
                    .foregroundStyle(AppTheme.Colors.cone50)
                }

                // Median path
                ForEach(dayIndices, id: \.self) { d in
                    LineMark(
                        x: .value("Day", d),
                        y: .value("Median", forecast.medianPath[d])
                    )
                    .foregroundStyle(AppTheme.Colors.medianLine)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // Start price reference
                RuleMark(y: .value("Start", forecast.startPrice))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
            .chartXAxisLabel("Trading Days")
            .chartYAxisLabel("Price (\(forecast.asset.currency))")
            .chartYAxis { AxisMarks(position: .trailing) }
            .frame(height: 220)

            coneLegend
        }
    }

    private var coneLegend: some View {
        HStack(spacing: 16) {
            legendItem(color: AppTheme.Colors.cone95, label: "5–95th percentile")
            legendItem(color: AppTheme.Colors.cone50, label: "25–75th percentile")
            legendItem(color: AppTheme.Colors.medianLine, label: "Median", isLine: true)
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }

    private func legendItem(color: Color, label: String, isLine: Bool = false) -> some View {
        HStack(spacing: 4) {
            if isLine {
                Rectangle().fill(color).frame(width: 16, height: 2)
            } else {
                Rectangle().fill(color).frame(width: 12, height: 12).cornerRadius(2)
            }
            Text(label)
        }
    }
}
