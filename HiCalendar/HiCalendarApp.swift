//
//  HiCalendarApp.swift
//  HiCalendar
//
//  Created by Jerry  on 2025/8/8.
//

import SwiftUI
import SwiftData

@main
struct HiCalendarApp: App {
    @StateObject private var authManager = SupabaseManager.shared
    
    var sharedModelContainer: ModelContainer = {
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
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
