// TaskRowView.swift
// One row in the task list.
// WHY a separate file?
// TaskListView would become 200+ lines if we inlined this.
// Separate components = easier to read, easier to change.

import SwiftUI

struct TaskRowView: View {
    
    // WHY @ObservedObject for a single task?
    // Task is an NSManagedObject — it's a reference type that
    // CoreData manages. @ObservedObject makes the row redraw
    // when this specific task's properties change.
    @ObservedObject var task: Task
    var onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            
            // MARK: Checkmark button
            Button(action: onToggle) {
                Image(systemName: task.isCompleted
                      ? "checkmark.circle.fill"
                      : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    // WHY .animation here?
                    // This makes the circle → checkmark transition
                    // animate smoothly instead of snapping instantly.
                    .animation(.spring(response: 0.3), value: task.isCompleted)
            }
            .buttonStyle(.plain) // prevents the whole row from highlighting
            
            // MARK: Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.titleUnwrapped)
                    .font(.body)
                    .fontWeight(.medium)
                    // Strikethrough when completed — classic done effect
                    .strikethrough(task.isCompleted, color: .gray)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                // Notes preview (only show if exists)
                if !task.notesUnwrapped.isEmpty {
                    Text(task.notesUnwrapped)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Due date (only show if set)
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    .foregroundColor(
                        dueDate < Date() && !task.isCompleted
                        ? .red      // overdue = red
                        : .secondary // not due yet = gray
                    )
                }
            }
            
            Spacer()
            
            // MARK: Priority badge
            Text(task.priorityEmoji)
                .font(.title3)
        }
        .padding(.vertical, 4)
        // Dim completed tasks slightly
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }
}
