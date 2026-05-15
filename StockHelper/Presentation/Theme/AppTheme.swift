import SwiftUI

enum AppTheme {
    // MARK: - Colors
    enum Colors {
        static let bullish = Color("BullishGreen", bundle: nil)
        static let bearish = Color("BearishRed", bundle: nil)
        static let neutral = Color.secondary

        // Probability cone bands
        static let cone95 = Color.blue.opacity(0.10)
        static let cone50 = Color.blue.opacity(0.22)
        static let medianLine = Color.blue

        static let confidenceHigh   = Color.green
        static let confidenceMedium = Color.orange
        static let confidenceLow    = Color.red

        static func bullBear(_ isBullish: Bool) -> Color { isBullish ? bullish : bearish }
        static func direction(_ direction: SignalDirection) -> Color {
            switch direction {
            case .bullish: bullish
            case .bearish: bearish
            case .neutral: neutral
            }
        }
    }

    // MARK: - Typography
    enum Font {
        static let priceDisplay = SwiftUI.Font.system(size: 32, weight: .bold, design: .rounded)
        static let sectionHeader = SwiftUI.Font.headline
        static let statLabel = SwiftUI.Font.caption
        static let disclaimer = SwiftUI.Font.caption2
    }

    // MARK: - Layout
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
}

// MARK: - Convenience modifiers

extension View {
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.medium)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
    }

    func disclaimerStyle() -> some View {
        self
            .font(AppTheme.Font.disclaimer)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
    }
}
