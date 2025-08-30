import Foundation
import Combine

@MainActor
final class CatalogStore: ObservableObject {
    static let shared = CatalogStore()

    @Published private(set) var catalog: Catalog = Catalog(environments: [:])

    private init() { 
        load() 
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            assertionFailure("catalog.json missing from bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            catalog = try decoder.decode(Catalog.self, from: data)
        } catch {
            assertionFailure("Failed to decode catalog.json: \(error)")
        }
    }

    // Convenience
    func items(in environment: String) -> [Item] {
        catalog.environments[environment, default: []]
    }
    
    // Check if catalog is loaded
    var isLoaded: Bool {
        !catalog.environments.isEmpty
    }
}

