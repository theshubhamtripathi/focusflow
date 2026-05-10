// StreakViewModel.swift
// Handles all streak calculation and focus statistics.
//
// WHY is streak logic in a ViewModel and not a View?
// Streak calculation involves CoreData queries, date math,
// and aggregation logic. None of that belongs in a View.
// ViewModel = all logic. View = display only.

import Foundation
import CoreData
import Combine

// MARK: - DayData
// Represents one day's data for the heatmap
struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int      // total focus minutes that day
    let sessionCount: Int // number of sessions that day
    
    // Intensity for heatmap colour (0 = none, 1-4 = light to dark)
    var intensity: Int {
        switch minutes {
        case 0:       return 0
        case 1...25:  return 1
        case 26...50: return 2
        case 51...75: return 3
        default:      return 4
        }
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var hadActivity: Bool { minutes > 0 }
}

// MARK: - StreakViewModel
class StreakViewModel: ObservableObject {
    
    // MARK: - Published
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var todayMinutes: Int = 0
    @Published var todaySessions: Int = 0
    @Published var weeklyData: [DayData] = []
    @Published var heatmapData: [DayData] = []
    @Published var totalFocusMinutes: Int = 0
    @Published var totalSessions: Int = 0
    
    private var context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }
    
    // MARK: - Load All Data
    func loadData() {
        let sessions = fetchAllSessions()
        calculateStreaks(from: sessions)
        buildWeeklyData(from: sessions)
        buildHeatmapData(from: sessions)
        calculateTotals(from: sessions)
        calculateToday(from: sessions)
    }
    
    // MARK: - Fetch Sessions
    private func fetchAllSessions() -> [FocusSession] {
        let request = NSFetchRequest<FocusSession>(
            entityName: "FocusSession"
        )
        // Only count completed work sessions
        // WHY this predicate?
        // Incomplete or abandoned sessions shouldn't count toward
        // streaks. Only sessions the user actually finished matter.
        request.predicate = NSPredicate(
            format: "wasCompleted == YES AND sessionType == %@", "work"
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \FocusSession.date, ascending: true)
        ]
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Streak Calculation
    // WHY this algorithm?
    // We group sessions by calendar day, get a sorted array of
    // unique active days, then count backwards from today to find
    // how many consecutive days have activity.
    private func calculateStreaks(from sessions: [FocusSession]) {
        // Get unique days that had at least one completed session
        let activeDays = uniqueActiveDays(from: sessions)
        
        guard !activeDays.isEmpty else {
            currentStreak = 0
            longestStreak = 0
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // MARK: Current streak
        // Start from today and walk backwards
        // If today OR yesterday had activity, streak is alive
        var streak = 0
        var checkDate = today
        
        // Check if streak is still alive (today or yesterday had activity)
        let hasToday = activeDays.contains(today)
        let hasYesterday = activeDays.contains(yesterday)
        
        if hasToday || hasYesterday {
            // Start checking from today backwards
            checkDate = hasToday ? today : yesterday
            
            while activeDays.contains(checkDate) {
                streak += 1
                checkDate = calendar.date(
                    byAdding: .day, value: -1, to: checkDate
                )!
            }
        }
        currentStreak = streak
        
        // MARK: Longest streak ever
        // Walk through ALL active days and find longest consecutive run
        var longest = 0
        var current = 1
        let sortedDays = activeDays.sorted()
        
        for i in 1..<sortedDays.count {
            let prev = sortedDays[i - 1]
            let curr = sortedDays[i]
            let diff = calendar.dateComponents(
                [.day], from: prev, to: curr
            ).day ?? 0
            
            if diff == 1 {
                // Consecutive day — extend the run
                current += 1
                longest = max(longest, current)
            } else {
                // Gap found — reset run
                current = 1
            }
        }
        longest = max(longest, current)
        longestStreak = max(longest, currentStreak)
    }
    
    // MARK: - Unique Active Days
    private func uniqueActiveDays(from sessions: [FocusSession]) -> Set<Date> {
        // WHY Set<Date>?
        // Sets automatically deduplicate. If a user did 5 sessions
        // on Monday, Monday appears only once in the Set.
        // This is exactly what we need for streak calculation.
        var days = Set<Date>()
        let calendar = Calendar.current
        
        for session in sessions {
            guard let date = session.date else { continue }
            // Normalise to midnight so all sessions on same day
            // map to the same Date value
            let dayStart = calendar.startOfDay(for: date)
            days.insert(dayStart)
        }
        return days
    }
    
    // MARK: - Weekly Data (last 7 days)
    private func buildWeeklyData(from sessions: [FocusSession]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        weeklyData = (0..<7).reversed().map { daysAgo in
            let date = calendar.date(
                byAdding: .day, value: -daysAgo, to: today
            )!
            
            // Sessions on this specific day
            let daySessions = sessions.filter {
                guard let d = $0.date else { return false }
                return calendar.startOfDay(for: d) == date
            }
            
            let minutes = daySessions.reduce(0) {
                $0 + Int($1.duration) / 60
            }
            
            return DayData(
                date: date,
                minutes: minutes,
                sessionCount: daySessions.count
            )
        }
    }
    
    // MARK: - Heatmap Data (last 12 weeks = 84 days)
    private func buildHeatmapData(from sessions: [FocusSession]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // WHY 84 days?
        // 12 weeks × 7 days = 84 squares.
        // This matches the GitHub contribution graph style
        // which users immediately recognise and understand.
        heatmapData = (0..<84).reversed().map { daysAgo in
            let date = calendar.date(
                byAdding: .day, value: -daysAgo, to: today
            )!
            
            let daySessions = sessions.filter {
                guard let d = $0.date else { return false }
                return calendar.startOfDay(for: d) == date
            }
            
            let minutes = daySessions.reduce(0) {
                $0 + Int($1.duration) / 60
            }
            
            return DayData(
                date: date,
                minutes: minutes,
                sessionCount: daySessions.count
            )
        }
    }
    
    // MARK: - Totals
    private func calculateTotals(from sessions: [FocusSession]) {
        totalSessions = sessions.count
        totalFocusMinutes = sessions.reduce(0) {
            $0 + Int($1.duration) / 60
        }
    }
    
    // MARK: - Today
    private func calculateToday(from sessions: [FocusSession]) {
        let calendar = Calendar.current
        let todaySess = sessions.filter {
            guard let d = $0.date else { return false }
            return calendar.isDateInToday(d)
        }
        todaySessions = todaySess.count
        todayMinutes = todaySess.reduce(0) { $0 + Int($1.duration) / 60 }
    }
    
    // MARK: - Helpers
    var totalFocusHours: String {
        let hours = totalFocusMinutes / 60
        let mins = totalFocusMinutes % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }
    
    var streakMessage: String {
        switch currentStreak {
        case 0:     return "Start your streak today! 🌱"
        case 1:     return "Great start! Keep it going! 🔥"
        case 2...4: return "Building momentum! 💪"
        case 5...9: return "You're on fire! 🔥🔥"
        case 10...19: return "Incredible discipline! 🏆"
        default:    return "Legendary streak! 🚀"
        }
    }
    
    // Max minutes in a week (for bar chart scaling)
    var weeklyMax: Int {
        max(weeklyData.map { $0.minutes }.max() ?? 1, 1)
    }
    
    // Day label for heatmap column headers
    func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }
}
