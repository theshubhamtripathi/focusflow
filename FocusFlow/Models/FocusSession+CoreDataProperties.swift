// FocusSession+CoreDataProperties.swift

import Foundation
import CoreData

extension FocusSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusSession> {
        return NSFetchRequest<FocusSession>(entityName: "FocusSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var duration: Int32
    @NSManaged public var sessionType: String?
    @NSManaged public var wasCompleted: Bool
    @NSManaged public var date: Date?
    @NSManaged public var task: Task?
}

// MARK: - Computed Properties
extension FocusSession {

    // Duration formatted as "25 min" for display in UI
    var durationLabel: String {
        let minutes = duration / 60
        return "\(minutes) min"
    }

    // Is this a work session or break session?
    var isWorkSession: Bool {
        sessionType == "work"
    }

    var sessionTypeLabel: String {
        isWorkSession ? "🍅 Work" : "☕ Break"
    }

    var dateUnwrapped: Date { date ?? Date() }
    var startTimeUnwrapped: Date { startTime ?? Date() }
}
extension FocusSession: Identifiable {}
