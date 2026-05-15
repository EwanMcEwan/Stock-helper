import SwiftUI

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @EnvironmentObject var deps: AppDependencies
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if viewModel.isSearching {
                    HStack {
                        ProgressView()
                        Text("Searching…").foregroundColor(.secondary)
                    }
                } else if let error = viewModel.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                } else {
                    ForEach(viewModel.results) { asset in
                        NavigationLink(value: asset) {
                            AssetRowView(asset: asset)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Symbol or company name")
            .navigationTitle("Search")
            .navigationDestination(for: Asset.self) { asset in
                AssetDetailView(viewModel: deps.makeAssetDetailViewModel(asset: asset))
                    .environmentObject(deps)
            }
        }
    }
}

struct AssetRowView: View {
    let asset: Asset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.id)
                    .font(.headline)
                Text(asset.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(asset.exchange)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(asset.kind.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}
