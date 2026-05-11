// TimerViewModel.swift
// The brain of the Pomodoro timer.
// Handles countdown, work/break cycles, and session tracking.

import UserNotifications
import Foundation
import Combine
import CoreData
import SwiftUI

// MARK: - Timer State
enum TimerState {
    case idle
    case running
    case paused
    case finished
}

// MARK: - Session Type
enum SessionType {
    case work
    case shortBreak
    case longBreak
    
    var label: String {
        switch self {
        case .work:       return "Focus Time"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }
    
    var emoji: String {
        switch self {
        case .work:       return "🍅"
        case .shortBreak: return "☕"
        case .longBreak:  return "🛌"
        }
    }
    
    var color: String {
        switch self {
        case .work:       return "red"
        case .shortBreak: return "green"
        case .longBreak:  return "blue"
        }
    }
}

// MARK: - TimerViewModel
class TimerViewModel: ObservableObject {
    
    // MARK: - AppStorage Settings
    // WHY @AppStorage here?
    // Settings screen saves values to UserDefaults via @AppStorage.
    // Reading them here with the same keys means the timer
    // automatically uses whatever duration the user set.
    // Change 25min to 30min in Settings → timer uses 30min instantly.
    @AppStorage("workDuration") private var workDurationSetting: Int = 25
    @AppStorage("shortBreakDuration") private var shortBreakSetting: Int = 5
    @AppStorage("longBreakDuration") private var longBreakSetting: Int = 15
    @AppStorage("sessionsBeforeLongBreak") private var sessionsSetting: Int = 4
    
    // MARK: - Published Properties
    @Published var timeRemaining: Int = 25 * 60
    @Published var timerState: TimerState = .idle
    @Published var sessionType: SessionType = .work
    @Published var currentSession: Int = 1
    @Published var totalSessions: Int = 4
    @Published var selectedTask: Task? = nil
    @Published var showTaskPicker: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var timerSubscription: AnyCancellable?
    private var sessionStartTime: Date?
    private var context: NSManagedObjectContext
    
    // MARK: - Computed Properties
    
    // Duration reads from AppStorage settings
    // WHY computed and not stored?
    // If user changes settings mid-session, the NEXT session
    // picks up the new duration automatically.
    var currentWorkDuration: Int { workDurationSetting * 60 }
    var currentShortBreak: Int { shortBreakSetting * 60 }
    var currentLongBreak: Int { longBreakSetting * 60 }
    
    var totalDuration: Int {
        switch sessionType {
        case .work:       return currentWorkDuration
        case .shortBreak: return currentShortBreak
        case .longBreak:  return currentLongBreak
        }
    }
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(timeRemaining) / Double(totalDuration)
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var isWorkSession: Bool { sessionType == .work }
    
    var sessionDots: [Bool] {
        (1...totalSessions).map { $0 <= currentSession - 1 }
    }
    
    // MARK: - Init
    init(context: NSManagedObjectContext) {
        self.context = context
        // Set initial time from settings
        self.timeRemaining = workDurationSetting * 60
        self.totalSessions = sessionsSetting
    }
    
    // MARK: - Timer Controls
    func start() {
        guard timerState != .running else { return }
        timerState = .running
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        timerSubscription = Timer.publish(
            every: 1, on: .main, in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        guard timerState == .running else { return }
        timerState = .paused
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    func reset() {
        timerSubscription?.cancel()
        timerSubscription = nil
        timerState = .idle
        timeRemaining = totalDuration
        sessionStartTime = nil
    }
    
    func skip() {
        timerSubscription?.cancel()
        timerSubscription = nil
        sessionStartTime = nil
        moveToNextSession()
    }
    
    // MARK: - Tick
    private func tick() {
        guard timeRemaining > 0 else {
            sessionCompleted()
            return
        }
        timeRemaining -= 1
    }
    
    // MARK: - Session Completed
    private func sessionCompleted() {
        timerSubscription?.cancel()
        timerSubscription = nil
        timerState = .finished
        
        if isWorkSession {
            saveSession(wasCompleted: true)
            DispatchQueue.main.async {
                NotificationManager.shared
                    .scheduleWorkSessionEndNotification()
            }
        } else {
            DispatchQueue.main.async {
                NotificationManager.shared
                    .scheduleBreakEndNotification()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.moveToNextSession()
        }
    }
    
    // MARK: - Session Progression
    // WHY sessionsSetting here?
    // Standard Pomodoro uses 4 sessions before long break.
    // But user can change this in Settings (2-6 sessions).
    // Reading sessionsSetting means their preference is respected.
    private func moveToNextSession() {
        if isWorkSession {
            if currentSession >= sessionsSetting {
                sessionType = .longBreak
                currentSession = 1
            } else {
                sessionType = .shortBreak
                currentSession += 1
            }
        } else {
            sessionType = .work
        }
        timeRemaining = totalDuration
        timerState = .idle
        sessionStartTime = nil
    }
    
    // MARK: - CoreData Save
    private func saveSession(wasCompleted: Bool) {
        guard let startTime = sessionStartTime else { return }
        let session = FocusSession(
            context: context,
            duration: Int32(totalDuration),
            sessionType: "work"
        )
        session.startTime = startTime
        session.endTime = Date()
        session.wasCompleted = wasCompleted
        session.task = selectedTask
        if let task = selectedTask {
            task.addToSessions(session)
        }
        do {
            try context.save()
        } catch {
            print("Session save error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Settings Update
    // Called when user changes durations in Settings
    func updateDurations(work: Int, shortBreak: Int, longBreak: Int) {
        reset()
        timeRemaining = totalDuration
    }
}
