//
//  MartyApp.swift
//  Marty
//
//  Optimized app entry point with lazy loading for better startup performance
//

import SwiftUI
import SwiftData

@main
struct MartyApp: App {
    
    // Static model container - lazily initialized on first access without requiring a mutating getter
    private static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.services, ServiceContainer.shared)
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
