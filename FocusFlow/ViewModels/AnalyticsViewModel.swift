// AnalyticsViewModel.swift
// Aggregates CoreData session data into chart-ready structures.
//
// WHY a separate ViewModel for Analytics?
// StreakViewModel already handles streak data.
// AnalyticsViewModel handles a different concern — detailed
// breakdowns, completion rates, hourly patterns.
// One ViewModel per screen = clean separation.

import Foundation
import CoreData
import Combine

// MARK: - Chart Data Structures

// For bar/line charts
struct FocusDataPoint: Identifiable {
    let id = UUID()
    let label: String   // x-axis label
    let minutes: Int    // y-axis value
    let date: Date
}

// For completion rate donut
struct CompletionData: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let color: String
}

// For hourly heatmap
struct HourlyData: Identifiable {
    let id = UUID()
    let hour: Int
    let sessions: Int
    
    var hourLabel: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return "\(h)\(hour < 12 ? "am" : "pm")"
    }
}

// MARK: - AnalyticsViewModel
class AnalyticsViewModel: ObservableObject {
    
    @Published var weeklyData: [FocusDataPoint] = []
    @Published var monthlyData: [FocusDataPoint] = []
    @Published var completionData: [CompletionData] = []
    @Published var hourlyData: [HourlyData] = []
    @Published var averageDailyMinutes: Int = 0
    @Published var mostProductiveHour: String = "--"
    @Published var bestDay: String = "--"
    @Published var taskCompletionRate: Double = 0
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }
    
    // MARK: - Load All
    func loadData() {
        let sessions = fetchSessions()
        let tasks = fetchTasks()
        
        buildWeeklyData(from: sessions)
        buildMonthlyData(from: sessions)
        buildCompletionData(from: tasks)
        buildHourlyData(from: sessions)
        calculateStats(from: sessions)
    }
    
    // MARK: - Fetch
    private func fetchSessions() -> [FocusSession] {
        let request = NSFetchRequest<FocusSession>(
            entityName: "FocusSession"
        )
        request.predicate = NSPredicate(
            format: "wasCompleted == YES AND sessionType == %@",
            "work"
        )
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \FocusSession.startTime,
                ascending: true
            )
        ]
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchTasks() -> [Task] {
        let request = NSFetchRequest<Task>(entityName: "Task")
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Weekly Data
    private func buildWeeklyData(from sessions: [FocusSession]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        weeklyData = (0..<7).reversed().map { daysAgo in
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
            
            // Short day label for x-axis
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let label = String(
                formatter.string(from: date).prefix(3)
            )
            
            return FocusDataPoint(
                label: label,
                minutes: minutes,
                date: date
            )
        }
        
        // Average
        let total = weeklyData.reduce(0) { $0 + $1.minutes }
        averageDailyMinutes = total / 7
    }
    
    // MARK: - Monthly Data (last 4 weeks)
    private func buildMonthlyData(from sessions: [FocusSession]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        monthlyData = (0..<4).reversed().map { weeksAgo in
            let weekStart = calendar.date(
                byAdding: .day, value: -(weeksAgo * 7), to: today
            )!
            let weekEnd = calendar.date(
                byAdding: .day, value: 6, to: weekStart
            )!
            
            let weekSessions = sessions.filter {
                guard let d = $0.date else { return false }
                let day = calendar.startOfDay(for: d)
                return day >= weekStart && day <= weekEnd
            }
            
            let minutes = weekSessions.reduce(0) {
                $0 + Int($1.duration) / 60
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let label = formatter.string(from: weekStart)
            
            return FocusDataPoint(
                label: label,
                minutes: minutes,
                date: weekStart
            )
        }
    }
    
    // MARK: - Task Completion Rate
    private func buildCompletionData(from tasks: [Task]) {
        let completed = tasks.filter { $0.isCompleted }.count
        let incomplete = tasks.filter { !$0.isCompleted }.count
        
        guard !tasks.isEmpty else {
            taskCompletionRate = 0
            completionData = []
            return
        }
        
        taskCompletionRate = Double(completed) / Double(tasks.count) * 100
        
        completionData = [
            CompletionData(
                label: "Completed",
                count: completed,
                color: "green"
            ),
            CompletionData(
                label: "In Progress",
                count: incomplete,
                color: "blue"
            )
        ]
    }
    
    // MARK: - Hourly Pattern
    // WHY hourly analysis?
    // Knowing your peak focus hours is incredibly valuable.
    // Are you a morning person or night owl?
    // This chart answers that with real data.
    private func buildHourlyData(from sessions: [FocusSession]) {
        var hourlyCounts = [Int: Int]()
        
        for session in sessions {
            guard let start = session.startTime else { continue }
            let hour = Calendar.current.component(.hour, from: start)
            hourlyCounts[hour, default: 0] += 1
        }
        
        // Show working hours 6am to 11pm
        hourlyData = (6...23).map { hour in
            HourlyData(hour: hour, sessions: hourlyCounts[hour] ?? 0)
        }
        
        // Most productive hour
        if let peak = hourlyCounts.max(by: { $0.value < $1.value }) {
            let h = peak.key % 12 == 0 ? 12 : peak.key % 12
            let ampm = peak.key < 12 ? "am" : "pm"
            mostProductiveHour = "\(h)\(ampm)"
        }
    }
    
    // MARK: - Stats
    private func calculateStats(from sessions: [FocusSession]) {
        guard !sessions.isEmpty else { return }
        
        // Best day of week
        var dayCounts = [Int: Int]()
        for session in sessions {
            guard let date = session.date else { continue }
            let weekday = Calendar.current.component(
                .weekday, from: date
            )
            dayCounts[weekday, default: 0] += 1
        }
        
        if let bestWeekday = dayCounts.max(
            by: { $0.value < $1.value }
        ) {
            let formatter = DateFormatter()
            let days = formatter.weekdaySymbols ?? []
            if bestWeekday.key - 1 < days.count {
                bestDay = String(days[bestWeekday.key - 1].prefix(3))
            }
        }
    }
    
    // Max for chart scaling
    var weeklyMax: Int {
        max(weeklyData.map { $0.minutes }.max() ?? 1, 1)
    }
    
    var monthlyMax: Int {
        max(monthlyData.map { $0.minutes }.max() ?? 1, 1)
    }
}
