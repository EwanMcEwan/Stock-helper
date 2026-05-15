import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var showAVKey = false
    @State private var showFHKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section("API Keys (optional — raise rate limits)") {
                    SecureFieldWithToggle(label: "Alpha Vantage Key", text: $viewModel.alphaVantageKey, isVisible: $showAVKey)
                    SecureFieldWithToggle(label: "Finnhub Key", text: $viewModel.finnhubKey, isVisible: $showFHKey)
                    Text("Without keys the app falls back to Yahoo Finance (no key required). Keys are stored only in UserDefaults on this device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Display") {
                    Picker("Default Currency", selection: $viewModel.defaultCurrency) {
                        ForEach(viewModel.currencyOptions, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    NavigationLink("Disclaimer") {
                        DisclaimerDetailView()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

struct SecureFieldWithToggle: View {
    let label: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack {
            if isVisible {
                TextField(label, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField(label, text: $text)
            }
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DisclaimerDetailView: View {
    var body: some View {
        ScrollView {
            Text(Forecast.standardDisclaimer)
                .padding()
                .font(.body)
        }
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
