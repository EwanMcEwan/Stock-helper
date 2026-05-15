import Foundation

enum AssetKind: String, Codable, CaseIterable {
    case stock = "Stock"
    case etf = "ETF"
    case etn = "ETN"
    case etc = "ETC"
    case etp = "ETP"
    case leveragedETP = "Leveraged ETP"
}

struct Asset: Identifiable, Hashable, Codable {
    let id: String          // e.g. "AAPL", "VWCE.DE", "3LTS.L"
    let name: String
    let exchange: String
    let kind: AssetKind
    let currency: String
    let description: String?

    var exchangeSuffix: String? {
        let parts = id.split(separator: ".")
        return parts.count > 1 ? String(parts.last!) : nil
    }

    var isEuropean: Bool {
        let europeanSuffixes = ["L", "DE", "PA", "AS", "MI", "BR", "MC", "LS", "SW"]
        return exchangeSuffix.map { europeanSuffixes.contains($0) } ?? false
    }
}
