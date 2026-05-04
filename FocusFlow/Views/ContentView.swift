// ContentView.swift
// Root view of the app — a TabView with all main sections.
// WHY TabView?
// FocusFlow has 4 features: Tasks, Timer, Streaks, Analytics.
// TabView is the standard iOS pattern for top-level navigation
// between distinct features. Users instantly understand it.

import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        TabView {
            
            // Tasks tab
            TaskListView(context: context)
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }
            
            // Timer tab (placeholder for Day 3)
            NavigationView {
                Text("🍅 Pomodoro Timer\nComing Day 3")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .navigationTitle("Focus Timer")
            }
            .tabItem {
                Label("Focus", systemImage: "timer")
            }
            
            // Streaks tab (placeholder for Day 5)
            NavigationView {
                Text("🔥 Streaks\nComing Day 5")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .navigationTitle("Streaks")
            }
            .tabItem {
                Label("Streaks", systemImage: "flame")
            }
            
            // Analytics tab (placeholder for Day 6)
            NavigationView {
                Text("📊 Analytics\nComing Day 6")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .navigationTitle("Analytics")
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar")
            }
        }
    }
}
