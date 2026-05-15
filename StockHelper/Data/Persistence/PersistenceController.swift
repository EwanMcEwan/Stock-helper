import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    var container: ModelContainer?

    func setup() async {
        let schema = Schema([
            AssetEntity.self,
            PriceBarEntity.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Fallback to in-memory if disk setup fails
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: fallback)
        }
    }

    var context: ModelContext? { container?.mainContext }
}
