import Foundation
import SwiftData

@Model
final class AssetEntity {
    @Attribute(.unique) var symbol: String
    var name: String
    var exchange: String
    var kind: String
    var currency: String
    var isWatchlisted: Bool
    var lastUpdated: Date

    init(asset: Asset, isWatchlisted: Bool = false) {
        self.symbol = asset.id
        self.name = asset.name
        self.exchange = asset.exchange
        self.kind = asset.kind.rawValue
        self.currency = asset.currency
        self.isWatchlisted = isWatchlisted
        self.lastUpdated = Date()
    }

    func toDomain() -> Asset {
        Asset(
            id: symbol,
            name: name,
            exchange: exchange,
            kind: AssetKind(rawValue: kind) ?? .stock,
            currency: currency,
            description: nil
        )
    }
}
