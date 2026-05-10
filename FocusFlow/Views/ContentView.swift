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
