// TaskViewModel.swift
// The ViewModel for all task operations.
// WHY ObservableObject?
// SwiftUI Views can "observe" this class. When any @Published
// property changes, every View watching it automatically redraws.
// This is the core of SwiftUI's reactive UI system.

import Foundation
import CoreData
import SwiftUI
import Combine

class TaskViewModel: ObservableObject {
    
    // MARK: - Properties
    
    // @Published means "when this changes, tell all watching Views"
    // tasks array is what the List will display
    @Published var tasks: [Task] = []
    @Published var showingAddTask = false
    
    // Form fields for the Add Task sheet
    @Published var newTaskTitle = ""
    @Published var newTaskNotes = ""
    @Published var newTaskPriority: Int16 = 1
    @Published var newTaskDueDate = Date()
    @Published var showDueDate = false
    
    // The CoreData context — our connection to the database
    // WHY private(set)?
    // External code can read it but only this ViewModel can change it.
    private var context: NSManagedObjectContext
    
    // MARK: - Init
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTasks() // load tasks immediately on init
    }
    
    // MARK: - Fetch
    // WHY a separate fetchTasks() function?
    // We call this after every create/delete/update so the
    // UI always reflects the current database state.
    func fetchTasks() {
        let request = NSFetchRequest<Task>(entityName: "Task")
        
        // Sort: incomplete tasks first, then by creation date
        // This way completed tasks sink to the bottom naturally
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Task.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)
        ]
        
        do {
            tasks = try context.fetch(request)
        } catch {
            print("Fetch error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Create
    func addTask() {
        // Guard prevents adding empty tasks
        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Use our convenience init from Day 1
        let task = Task(context: context, title: newTaskTitle)
        task.notes = newTaskNotes
        task.priority = newTaskPriority
        
        if showDueDate {
            task.dueDate = newTaskDueDate
        }
        
        // Save to CoreData
        saveContext()
        
        // Reset the form
        resetForm()
        
        // Refresh the list
        fetchTasks()
    }
    
    // MARK: - Delete
    // WHY IndexSet?
    // SwiftUI's .onDelete passes an IndexSet — the positions
    // of rows the user swiped to delete. We use it to find
    // the actual Task objects to remove from CoreData.
    func deleteTask(at offsets: IndexSet) {
        offsets.forEach { index in
            let task = tasks[index]
            context.delete(task)
        }
        saveContext()
        fetchTasks()
    }
    
    // MARK: - Toggle Complete
    func toggleComplete(task: Task) {
        task.isCompleted.toggle()
        
        // Record when it was completed
        task.completedAt = task.isCompleted ? Date() : nil
        
        saveContext()
        
        // Small delay so the checkmark animation plays
        // before the task moves to the bottom of the list
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fetchTasks()
        }
    }
    
    // MARK: - Save
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reset Form
    func resetForm() {
        newTaskTitle = ""
        newTaskNotes = ""
        newTaskPriority = 1
        newTaskDueDate = Date()
        showDueDate = false
        showingAddTask = false
    }
    
    // MARK: - Computed
    var incompleteTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }
    
    var completionPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count) * 100
    }
}
