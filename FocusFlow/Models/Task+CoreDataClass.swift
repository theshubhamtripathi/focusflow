// Task+CoreDataClass.swift
// The actual class definition for our Task entity.
//
// WHY @objc(Task)?
// CoreData was built on Objective-C. The @objc annotation tells
// the Objective-C runtime "this Swift class is named Task".
// Without it, CoreData can't find your class at runtime and crashes.

import Foundation
import CoreData

@objc(Task)
public class Task: NSManagedObject {
    
    // WHY a convenience init?
    // Every Task needs an id, title, and createdAt at minimum.
    // This init enforces that — you literally can't create a Task
    // without a title. No more forgetting required fields.
    convenience init(context: NSManagedObjectContext, title: String) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.isCompleted = false
        self.priority = 1 // medium by default
    }
}
