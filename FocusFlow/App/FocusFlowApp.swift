// FocusFlowApp.swift
// Entry point of the app. We inject the CoreData context here
// so every View in the app can access it via @Environment.

import SwiftUI
import CoreData

@main
struct FocusFlowApp: App {
    
    // PersistenceController is a singleton — one shared instance
    // manages the entire CoreData stack for the app.
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // This line injects the CoreData context into the
                // SwiftUI environment. Any view can then access it
                // with @Environment(\.managedObjectContext)
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
        }
    }
}
