// ContentView.swift
import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        TabView {
            
            TaskListView(context: context)
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }
            
            TimerView(context: context)
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
            
            StreakView(context: context)
                .tabItem {
                    Label("Streaks", systemImage: "flame")
                }
            
            // NOW REAL — replaces placeholder
            AnalyticsView(context: context)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
        }
    }
}
