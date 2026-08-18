//
//  AIEmotionsApp.swift
//  AIEmotions
//

import SwiftUI
import SwiftData

@main
struct AIEmotionsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([User.self, Post.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
