// TimerViewModel.swift
// The brain of the Pomodoro timer.
// Handles countdown, work/break cycles, and session tracking.
import UserNotifications
import Foundation
import Combine
import CoreData

// MARK: - Timer State
// WHY an enum for state?
// Booleans like isRunning + isPaused + isBreak get confusing fast.
// An enum makes the state explicit — the timer is ALWAYS in
// exactly one of these states. No contradictions possible.
enum TimerState {
    case idle       // not started yet
    case running    // counting down
    case paused     // paused mid-session
    case finished   // session complete
}

// MARK: - Session Type
enum SessionType {
    case work
    case shortBreak
    case longBreak
    
    var duration: Int {
        switch self {
        case .work:       return 25 * 60  // 25 minutes
        case .shortBreak: return 5 * 60   // 5 minutes
        case .longBreak:  return 15 * 60  // 15 minutes
        }
    }
    
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
    
    // MARK: - Published Properties
    // Everything the UI needs to display
    @Published var timeRemaining: Int = 25 * 60  // seconds
    @Published var timerState: TimerState = .idle
    @Published var sessionType: SessionType = .work
    @Published var currentSession: Int = 1       // 1 through 4
    @Published var totalSessions: Int = 4
    @Published var selectedTask: Task? = nil
    @Published var showTaskPicker: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    // WHY Set<AnyCancellable>?
    // Combine subscriptions need to be stored somewhere.
    // If you don't store them, they get deallocated immediately
    // and the timer stops working. This Set keeps them alive
    // as long as the ViewModel exists.
    
    private var timerSubscription: AnyCancellable?
    private var sessionStartTime: Date?
    private var context: NSManagedObjectContext
    
    // MARK: - Computed Properties
    
    // Total duration of current session type in seconds
    var totalDuration: Int {
        sessionType.duration
    }
    
    // Progress from 1.0 (full) down to 0.0 (empty)
    // WHY 1.0 - fraction?
    // The ring DRAINS as time runs out.
    // At start: timeRemaining = totalDuration → progress = 1.0 (full ring)
    // At end:   timeRemaining = 0            → progress = 0.0 (empty ring)
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(timeRemaining) / Double(totalDuration)
    }
    
    // Format seconds into MM:SS string
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        // %02d means "always show 2 digits, pad with 0 if needed"
        // So 5 seconds shows as "00:05" not "0:5"
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Is this a work session?
    var isWorkSession: Bool { sessionType == .work }
    
    // Session progress dots (○ ○ ○ ○ style display)
    var sessionDots: [Bool] {
        (1...totalSessions).map { $0 <= currentSession - 1 }
    }
    
    // MARK: - Init
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Timer Controls
    
    func start() {
        guard timerState != .running else { return }
        
        timerState = .running
        
        // Record when this session started (for CoreData)
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        
        // WHY Timer.publish?
        // This creates a Combine publisher that emits a value
        // every 1 second on the main thread (so UI updates work).
        // .autoconnect() starts it immediately.
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                // WHY [weak self]?
                // Without this, the timer holds a strong reference
                // to the ViewModel, creating a memory leak. weak self
                // breaks that cycle — if the ViewModel is deallocated,
                // the timer just does nothing instead of crashing.
                self?.tick()
            }
    }
    
    func pause() {
        guard timerState == .running else { return }
        timerState = .paused
        // Cancel the timer subscription — stops the ticking
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    func reset() {
        // Stop the timer
        timerSubscription?.cancel()
        timerSubscription = nil
        
        // Reset everything to initial state
        timerState = .idle
        timeRemaining = sessionType.duration
        sessionStartTime = nil
    }
    
    func skip() {
        // Skip to next session without saving
        timerSubscription?.cancel()
        timerSubscription = nil
        sessionStartTime = nil
        moveToNextSession()
    }
    
    // MARK: - Tick
    // Called every second by the Combine timer
    private func tick() {
        guard timeRemaining > 0 else {
            // Time's up!
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
    // WHY this logic?
    // Standard Pomodoro: 4 work sessions, short break after each,
    // long break after every 4th work session.
    private func moveToNextSession() {
        if isWorkSession {
            // Completed a work session
            if currentSession >= totalSessions {
                // After 4 work sessions — long break
                sessionType = .longBreak
                currentSession = 1
            } else {
                // After 1-3 work sessions — short break
                sessionType = .shortBreak
                currentSession += 1
            }
        } else {
            // Completed a break — back to work
            sessionType = .work
        }
        
        // Reset timer for new session type
        timeRemaining = sessionType.duration
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
        
        // Link to task's session count
        if let task = selectedTask {
            task.addToSessions(session)
        }
        
        do {
            try context.save()
        } catch {
            print("Session save error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Settings
    func updateDurations(work: Int, shortBreak: Int, longBreak: Int) {
        // For future settings screen on Day 7
        reset()
    }
}

