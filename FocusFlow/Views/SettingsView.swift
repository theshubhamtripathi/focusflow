// SettingsView.swift
// App settings — timer durations, notifications, about.

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    
    // WHY @AppStorage?
    // AppStorage persists values in UserDefaults automatically.
    // No CoreData needed for simple key-value settings.
    // The value survives app restarts with zero extra code.
    @AppStorage("workDuration") var workDuration: Int = 25
    @AppStorage("shortBreakDuration") var shortBreakDuration: Int = 5
    @AppStorage("longBreakDuration") var longBreakDuration: Int = 15
    @AppStorage("sessionsBeforeLongBreak") var sessionsBeforeLongBreak: Int = 4
    @AppStorage("dailyGoalMinutes") var dailyGoalMinutes: Int = 120
    @AppStorage("autoStartBreaks") var autoStartBreaks: Bool = false
    @AppStorage("autoStartWork") var autoStartWork: Bool = false
    @AppStorage("vibrationEnabled") var vibrationEnabled: Bool = true
}

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                
                // MARK: Timer Settings
                Section(header: Text("POMODORO TIMER")) {
                    
                    HStack {
                        Label("Focus Duration",
                              systemImage: "timer")
                        Spacer()
                        Stepper(
                            "\(viewModel.workDuration) min",
                            value: $viewModel.workDuration,
                            in: 5...60,
                            step: 5
                        )
                    }
                    
                    HStack {
                        Label("Short Break",
                              systemImage: "cup.and.saucer")
                        Spacer()
                        Stepper(
                            "\(viewModel.shortBreakDuration) min",
                            value: $viewModel.shortBreakDuration,
                            in: 1...15,
                            step: 1
                        )
                    }
                    
                    HStack {
                        Label("Long Break",
                              systemImage: "bed.double")
                        Spacer()
                        Stepper(
                            "\(viewModel.longBreakDuration) min",
                            value: $viewModel.longBreakDuration,
                            in: 10...30,
                            step: 5
                        )
                    }
                    
                    HStack {
                        Label("Sessions Before Long Break",
                              systemImage: "repeat")
                        Spacer()
                        Stepper(
                            "\(viewModel.sessionsBeforeLongBreak)",
                            value: $viewModel.sessionsBeforeLongBreak,
                            in: 2...6,
                            step: 1
                        )
                    }
                }
                
                // MARK: Auto Start
                Section(header: Text("AUTOMATION")) {
                    Toggle(isOn: $viewModel.autoStartBreaks) {
                        Label("Auto-start breaks",
                              systemImage: "play.circle")
                    }
                    Toggle(isOn: $viewModel.autoStartWork) {
                        Label("Auto-start work sessions",
                              systemImage: "play.circle.fill")
                    }
                }
                
                // MARK: Goals
                Section(header: Text("DAILY GOAL")) {
                    HStack {
                        Label("Daily Focus Goal",
                              systemImage: "target")
                        Spacer()
                        Stepper(
                            "\(viewModel.dailyGoalMinutes) min",
                            value: $viewModel.dailyGoalMinutes,
                            in: 25...480,
                            step: 25
                        )
                    }
                }
                
                // MARK: Notifications
                Section(header: Text("NOTIFICATIONS")) {
                    HStack {
                        Label("Status", systemImage:
                            notificationManager.isAuthorized
                            ? "bell.fill" : "bell.slash")
                        Spacer()
                        Text(notificationManager.isAuthorized
                             ? "Enabled" : "Disabled")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle(isOn: $viewModel.vibrationEnabled) {
                        Label("Vibration",
                              systemImage: "iphone.radiowaves.left.and.right")
                    }
                }
                
                // MARK: About
                Section(header: Text("ABOUT")) {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Developer",
                              systemImage: "person.circle")
                        Spacer()
                        Text("Shubham Tripathi")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Built with",
                              systemImage: "swift")
                        Spacer()
                        Text("SwiftUI + CoreData")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: Data
                Section(header: Text("DATA")) {
                    Button(role: .destructive) {
                        // Future: add confirmation alert
                    } label: {
                        Label("Reset All Data",
                              systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
