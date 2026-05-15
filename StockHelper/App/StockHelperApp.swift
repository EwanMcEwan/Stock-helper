import SwiftUI

@main
struct StockHelperApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environmentObject(dependencies)
                .task { await dependencies.configure() }
        }
    }
}

struct ContentRootView: View {
    @EnvironmentObject var deps: AppDependencies
    @State private var hasAcknowledgedDisclaimer = false

    var body: some View {
        if hasAcknowledgedDisclaimer {
            MainTabView()
        } else {
            DisclaimerView(onAccept: { hasAcknowledgedDisclaimer = true })
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var deps: AppDependencies

    var body: some View {
        TabView {
            SearchView(viewModel: deps.makeSearchViewModel())
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            WatchlistView(viewModel: deps.makeWatchlistViewModel())
                .tabItem { Label("Watchlist", systemImage: "star.fill") }

            SettingsView(viewModel: deps.makeSettingsViewModel())
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
