import UserNotifications
import Foundation
import Combine

class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    @Published var isAuthorized = false
    
    private init() { }
    
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter
                .current()
                .requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
            await MainActor.run { self.isAuthorized = granted }
        } catch {
            print("Permission error: \(error)")
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter
            .current().notificationSettings()
        await MainActor.run {
            self.isAuthorized =
                settings.authorizationStatus == .authorized
        }
    }
    
    func scheduleWorkSessionEndNotification() {
        scheduleNotification(
            id: "focusflow.work.end",
            title: "Focus session complete!",
            body: "Great work! Time to take a well-earned break."
        )
    }
    
    func scheduleBreakEndNotification() {
        scheduleNotification(
            id: "focusflow.break.end",
            title: "Breaks over!",
            body: "Ready to focus? Your next session awaits."
        )
    }
    
    func scheduleDailyReminder(hour: Int, minute: Int) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Time to focus!"
        content.body = "Your tasks are waiting."
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "focusflow.daily.reminder",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }
    
    func cancelWorkNotification() { }
    func cancelBreakNotification() { }
    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["focusflow.daily.reminder"]
            )
    }
    
    private func scheduleNotification(
        id: String,
        title: String,
        body: String
    ) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
