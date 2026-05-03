// PersistenceController.swift
// This file owns the entire CoreData stack.
// One class, one responsibility — the "single source of truth" for data.

import CoreData

struct PersistenceController {
    
    // MARK: - Singleton
    // 'shared' means there's only ONE PersistenceController in the whole app.
    // This prevents multiple database connections conflicting with each other.
    static let shared = PersistenceController()
    
    // MARK: - Container
    // NSPersistentContainer is Apple's wrapper around the CoreData stack.
    // "FocusFlow" must match your .xcdatamodeld filename exactly.
    let container: NSPersistentContainer
    
    // MARK: - Init
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FocusFlow")
        
        // inMemory: true is used for SwiftUI Previews and tests.
        // Data lives in RAM only — perfect for previews, nothing saved to disk.
        if inMemory {
            container.persistentStoreDescriptions.first?.url =
                URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // In production you'd handle this gracefully.
                // During development, crash loudly so you notice immediately.
                fatalError("CoreData failed to load: \(error.localizedDescription)")
            }
        }
        
        // Automatically merges changes from background contexts
        // into the main view context. Important for when we save data
        // from background threads later.
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Preview Helper
    // Used by SwiftUI Previews to get fake in-memory data.
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
    
    // MARK: - Save
    // Call this whenever you want to persist changes to disk.
    func save() {
        let context = container.viewContext
        
        // Only save if there are actual changes — no-op saves waste resources.
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error.localizedDescription)")
        }
    }
}
