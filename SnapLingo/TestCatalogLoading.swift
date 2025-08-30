import Foundation
import SwiftUI

// Test to verify catalog loading works correctly
struct TestCatalogLoading {
    static func testCatalogLoading() {
        print("=== Testing Catalog Loading ===")
        
        // Test 1: Check if catalog loads properly
        let catalogStore = CatalogStore.shared
        print("Initial catalog environments count: \(catalogStore.catalog.environments.count)")
        
        // Test 2: Check specific environment
        let homeKey = "home"
        let homeItems = catalogStore.catalog.environments[homeKey] ?? []
        print("Home environment items count: \(homeItems.count)")
        
        // Test 3: Check if items have proper structure
        if let firstItem = homeItems.first {
            print("First item: \(firstItem.word) - \(firstItem.emoji)")
        }
        
        // Test 4: Check all environments
        for (key, items) in catalogStore.catalog.environments {
            print("Environment '\(key)': \(items.count) items")
        }
        
        print("=== Test Complete ===")
    }
}
