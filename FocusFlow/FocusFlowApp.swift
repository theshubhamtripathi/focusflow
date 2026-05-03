//
//  FocusFlowApp.swift
//  FocusFlow
//
//  Created by Shubham Tripathi on 04/05/26.
//

import SwiftUI
import CoreData

@main
struct FocusFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
