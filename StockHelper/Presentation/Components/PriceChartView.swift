import SwiftUI
import Charts

struct PriceChartView: View {
    let bars: [PriceBar]
    let indicators: IndicatorResult?
    @State private var selectedBar: PriceBar?
    @State private var showSMA20 = true
    @State private var showSMA50 = true
    @State private var showBollinger = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if let selected = selectedBar {
                selectedBarInfo(selected)
            } else {
                latestPriceHeader
            }

            Chart {
                // Bollinger bands (behind everything)
                if showBollinger, let ind = indicators {
                    ForEach(Array(bars.enumerated()), id: \.offset) { i, bar in
                        if !ind.bollingerBands.upper[i].isNaN {
                            AreaMark(
                                x: .value("Date", bar.date),
                                yStart: .value("Lower", ind.bollingerBands.lower[i]),
                                yEnd: .value("Upper", ind.bollingerBands.upper[i])
                            )
                            .foregroundStyle(Color.purple.opacity(0.08))
                        }
                    }
                }

                // Candlestick-style bars
                ForEach(bars) { bar in
                    BarMark(
                        x: .value("Date", bar.date),
                        yStart: .value("Low", bar.low),
                        yEnd: .value("High", bar.high),
                        width: 1
                    )
                    .foregroundStyle(AppTheme.Colors.bullBear(bar.isBullish).opacity(0.5))

                    BarMark(
                        x: .value("Date", bar.date),
                        yStart: .value("Open", bar.open),
                        yEnd: .value("Close", bar.close),
                        width: 4
                    )
                    .foregroundStyle(AppTheme.Colors.bullBear(bar.isBullish))
                }

                // SMA overlays
                if showSMA20, let ind = indicators {
                    ForEach(Array(bars.enumerated()), id: \.offset) { i, bar in
                        if !ind.sma20[i].isNaN {
                            LineMark(x: .value("Date", bar.date), y: .value("SMA20", ind.sma20[i]))
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                        }
                    }
                }

                if showSMA50, let ind = indicators {
                    ForEach(Array(bars.enumerated()), id: \.offset) { i, bar in
                        if !ind.sma50[i].isNaN {
                            LineMark(x: .value("Date", bar.date), y: .value("SMA50", ind.sma50[i]))
                                .foregroundStyle(.blue)
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                        }
                    }
                }

                // Crosshair
                if let selected = selectedBar {
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
            .chartXAxis { AxisMarks(values: .stride(by: .month)) }
            .chartYAxis { AxisMarks(position: .trailing) }
            .chartOverlay { proxy in chartGesture(proxy: proxy) }
            .frame(height: 240)

            overlayToggles
        }
    }

    // MARK: - Subviews

    private var latestPriceHeader: some View {
        Group {
            if let last = bars.last {
                HStack(alignment: .firstTextBaseline) {
                    Text(last.close.formatted(.currency(code: "USD").precision(.fractionLength(2))))
                        .font(AppTheme.Font.priceDisplay)
                    Spacer()
                }
            }
        }
    }

    private func selectedBarInfo(_ bar: PriceBar) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(bar.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundColor(.secondary)
                Text("O: \(bar.open, specifier: "%.2f")  H: \(bar.high, specifier: "%.2f")  L: \(bar.low, specifier: "%.2f")  C: \(bar.close, specifier: "%.2f")")
                    .font(.caption).monospacedDigit()
            }
            Spacer()
        }
    }

    private var overlayToggles: some View {
        HStack(spacing: 12) {
            Toggle("SMA20", isOn: $showSMA20).toggleStyle(.button).tint(.orange)
            Toggle("SMA50", isOn: $showSMA50).toggleStyle(.button).tint(.blue)
            Toggle("BB", isOn: $showBollinger).toggleStyle(.button).tint(.purple)
        }
        .font(.caption)
    }

    // MARK: - Gesture

    private func chartGesture(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let x = val.location.x - geo.frame(in: .local).minX
                        if let date = proxy.value(atX: x, as: Date.self) {
                            selectedBar = bars.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
                        }
                    }
                    .onEnded { _ in selectedBar = nil }
                )
        }
    }
}
