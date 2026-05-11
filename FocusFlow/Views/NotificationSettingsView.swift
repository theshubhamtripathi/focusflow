// NotificationSettingsView.swift
import SwiftUI

struct NotificationSettingsView: View {
    
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    
    var body: some View {
        NavigationView {
            List {
                
                // Status Section
                Section(header: Text("STATUS")) {
                    HStack {
                        Image(systemName: notificationManager.isAuthorized
                              ? "checkmark.circle.fill"
                              : "xmark.circle.fill")
                            .foregroundColor(
                                notificationManager.isAuthorized
                                ? .green : .red
                            )
                        Text(notificationManager.isAuthorized
                             ? "Notifications enabled"
                             : "Notifications disabled")
                        Spacer()
                        if !notificationManager.isAuthorized {
                            Button("Enable") {
                                notificationManager.isAuthorized = true
                            }
                            .font(.subheadline)
                        }
                    }
                }
                
                // Daily Reminder Section
                Section(
                    header: Text("DAILY REMINDER"),
                    footer: Text("Get a daily nudge to complete your Pomodoro sessions.")
                ) {
                    Toggle("Daily reminder",
                           isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: reminderTime) {
                            let components = Calendar.current
                                .dateComponents(
                                    [.hour, .minute],
                                    from: reminderTime
                                )
                            notificationManager.scheduleDailyReminder(
                                hour: components.hour ?? 9,
                                minute: components.minute ?? 0
                            )
                        }
                    }
                }
                
                // Cancel Section
                Section {
                    Button("Cancel all notifications") {
                        notificationManager.cancelAll()
                        reminderEnabled = false
                    }
                    .foregroundColor(.red)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
