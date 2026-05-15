import SwiftUI

struct WatchlistView: View {
    @StateObject var viewModel: WatchlistViewModel
    @EnvironmentObject var deps: AppDependencies

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.items.isEmpty {
                    ContentUnavailableView(
                        "No Watchlist Items",
                        systemImage: "star",
                        description: Text("Search for a stock or ETF and add it to your watchlist.")
                    )
                } else {
                    List {
                        ForEach(viewModel.items, id: \.asset.id) { item in
                            NavigationLink(value: item.asset) {
                                WatchlistRowView(asset: item.asset, quote: item.quote)
                            }
                        }
                        .onDelete { viewModel.remove(at: $0) }
                    }
                    .refreshable { await viewModel.refresh() }
                }
            }
            .navigationTitle("Watchlist")
            .navigationDestination(for: Asset.self) { asset in
                AssetDetailView(viewModel: deps.makeAssetDetailViewModel(asset: asset))
                    .environmentObject(deps)
            }
            .task { await viewModel.load() }
        }
    }
}

struct WatchlistRowView: View {
    let asset: Asset
    let quote: Quote?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.id).font(.headline)
                Text(asset.name).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            if let quote {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(quote.price, format: .currency(code: asset.currency))
                        .font(.headline).monospacedDigit()
                    HStack(spacing: 2) {
                        Image(systemName: quote.isPositive ? "arrow.up" : "arrow.down")
                        Text("\(abs(quote.changePercent), specifier: "%.2f")%")
                    }
                    .font(.caption)
                    .foregroundColor(quote.isPositive ? AppTheme.Colors.bullish : AppTheme.Colors.bearish)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
