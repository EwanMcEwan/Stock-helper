import SwiftUI

struct DisclaimerView: View {
    let onAccept: () -> Void
    @State private var hasScrolledToBottom = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                Text("Stock Helper")
                    .font(.largeTitle.bold())
                Text("Educational & Informational Use Only")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 48)
            .padding(.bottom, AppTheme.Spacing.large)

            ScrollView {
                Text(Forecast.standardDisclaimer + """

By tapping "I Understand & Continue" you acknowledge that:
• Forecasts are probabilistic estimates, not guarantees.
• Past performance is not indicative of future results.
• This app does not provide financial advice.
• You will consult a qualified financial adviser before making investment decisions.
""")
                .font(.subheadline)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            Spacer()

            Button {
                onAccept()
            } label: {
                Text("I Understand & Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
    }
}
