// FocusSession+CoreDataClass.swift
// Represents one Pomodoro session — either a work block or a break.

import Foundation
import CoreData

@objc(FocusSession)
public class FocusSession: NSManagedObject {

    // WHY default sessionType to "work"?
    // 80% of sessions are work sessions. Making it the default
    // means less code at the call site — only break sessions
    // need to pass sessionType: "break" explicitly.
    convenience init(context: NSManagedObjectContext,
                     duration: Int32,
                     sessionType: String = "work") {
        self.init(context: context)
        self.id = UUID()
        self.startTime = Date()
        self.duration = duration
        self.sessionType = sessionType
        self.wasCompleted = false
        // Store just the calendar day (midnight) for streak tracking.
        // Later when we check "did user work today?" we compare
        // dates at day granularity, not exact timestamps.
        self.date = Calendar.current.startOfDay(for: Date())
    }
}
