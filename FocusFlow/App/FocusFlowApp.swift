// FocusFlowApp.swift
import SwiftUI
import CoreData

@main
struct FocusFlowApp: App {
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
                // WHY .task here?
                // .task runs async code when the view appears.
                // This is the RIGHT moment to ask for notification
                // permission — the user has the app open and is
                // engaged, not cold launching for the first time.
                .task {
                    await NotificationManager.shared.requestPermission()
                }
        }
    }
}
