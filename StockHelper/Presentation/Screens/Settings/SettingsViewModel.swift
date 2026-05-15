import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var alphaVantageKey: String {
        didSet { UserSettings.shared.alphaVantageKey = alphaVantageKey }
    }
    @Published var finnhubKey: String {
        didSet { UserSettings.shared.finnhubKey = finnhubKey }
    }
    @Published var defaultCurrency: String {
        didSet { UserSettings.shared.defaultCurrency = defaultCurrency }
    }

    let currencyOptions = ["USD", "EUR", "GBP", "CHF", "JPY"]

    init() {
        let settings = UserSettings.shared
        alphaVantageKey = settings.alphaVantageKey
        finnhubKey = settings.finnhubKey
        defaultCurrency = settings.defaultCurrency
    }
}

final class UserSettings {
    static let shared = UserSettings()
    private let defaults = UserDefaults.standard

    var alphaVantageKey: String {
        get { defaults.string(forKey: "av_key") ?? "" }
        set { defaults.set(newValue, forKey: "av_key") }
    }

    var finnhubKey: String {
        get { defaults.string(forKey: "fh_key") ?? "" }
        set { defaults.set(newValue, forKey: "fh_key") }
    }

    var defaultCurrency: String {
        get { defaults.string(forKey: "default_currency") ?? "USD" }
        set { defaults.set(newValue, forKey: "default_currency") }
    }
}
