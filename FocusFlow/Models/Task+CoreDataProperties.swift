// Task+CoreDataProperties.swift
// Declares all CoreData attributes as Swift properties.
//
// WHY split into two files (+Class and +Properties)?
// If you ever need to regenerate properties, Xcode only touches
// this file — your custom logic in +CoreDataClass stays safe.
// This is the standard Apple convention for CoreData classes.

import Foundation
import CoreData

extension Task {

    // WHY @nonobjc?
    // fetchRequest() is a Swift-only method. @nonobjc prevents
    // Objective-C from seeing it and causing selector conflicts.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    // WHY @NSManaged?
    // These properties don't actually live in Swift memory.
    // CoreData stores and retrieves them from its own stack at runtime.
    // @NSManaged tells Swift: "don't allocate storage for this,
    // CoreData will handle it." Without it, Swift would crash
    // trying to access uninitialized memory.
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var priority: Int16
    @NSManaged public var dueDate: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var sessions: NSSet?
}

// MARK: - Computed Properties
// These are regular Swift — not stored in CoreData.
// They're helpers that make our View code cleaner.
extension Task {

    // WHY convert NSSet to Array?
    // CoreData relationships return NSSet — an old Objective-C type
    // with no ordering and no SwiftUI support. We convert it to a
    // clean Swift Array sorted by date so ForEach works perfectly.
    var sessionsArray: [FocusSession] {
        let set = sessions as? Set<FocusSession> ?? []
        return set.sorted {
            ($0.startTime ?? Date()) < ($1.startTime ?? Date())
        }
    }

    // Human-readable priority for displaying in the UI
    var priorityLabel: String {
        switch priority {
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        default: return "Medium"
        }
    }

    // Emoji for priority — makes the UI expressive without extra code
    var priorityEmoji: String {
        switch priority {
        case 0: return "🟢"
        case 1: return "🟡"
        case 2: return "🔴"
        default: return "🟡"
        }
    }

    // WHY unwrapped properties?
    // CoreData optionals are annoying in SwiftUI. Every time you'd
    // write task.title ?? "Untitled" in the View. Instead we do it
    // once here and Views just write task.titleUnwrapped — clean.
    var titleUnwrapped: String { title ?? "Untitled Task" }
    var notesUnwrapped: String { notes ?? "" }
    var createdAtUnwrapped: Date { createdAt ?? Date() }

    // Total focus time spent on this task in minutes
    var totalFocusMinutes: Int {
        let total = sessionsArray
            .filter { $0.wasCompleted }
            .reduce(0) { $0 + Int($1.duration) }
        return total / 60
    }
}

// MARK: - NSSet helpers (CoreData relationship management)
extension Task {

    // These methods let us add/remove sessions cleanly.
    // CoreData generates these internally but since we're on
    // Manual/None, we write them ourselves.
    @objc(addSessionsObject:)
    @NSManaged public func addToSessions(_ value: FocusSession)

    @objc(removeSessionsObject:)
    @NSManaged public func removeFromSessions(_ value: FocusSession)

    @objc(addSessions:)
    @NSManaged public func addToSessions(_ values: NSSet)

    @objc(removeSessions:)
    @NSManaged public func removeFromSessions(_ values: NSSet)
}

// WHY Identifiable?
// SwiftUI's ForEach needs each item to have a unique id.
// By conforming Task to Identifiable and pointing to our
// UUID, ForEach knows exactly which row is which —
// essential for animations and swipe-to-delete to work correctly.
extension Task: Identifiable {}
