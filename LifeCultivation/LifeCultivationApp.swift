//
//  LifeCultivationApp.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

import SwiftData
import SwiftUI

@main
struct LifeCultivationApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyRecord.self, AppSettings.self
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
        }
        .modelContainer(sharedModelContainer)
    }
}
