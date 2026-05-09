// TaskDetailView.swift
// Full detail screen for a single task.
// WHY a detail view?
// The list row only shows a summary. Detail view shows everything:
// notes, due date, session history, focus time invested.
// This makes the app feel complete, not like a prototype.

import SwiftUI
import CoreData

struct TaskDetailView: View {
    
    // WHY @ObservedObject for task?
    // Task is an NSManagedObject — a reference type.
    // @ObservedObject makes this view redraw when the task
    // properties change (e.g. after editing).
    @ObservedObject var task: Task
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: Header
                headerSection
                
                // MARK: Details
                if !task.notesUnwrapped.isEmpty || task.dueDate != nil {
                    detailsSection
                }
                
                // MARK: Focus Stats
                focusStatsSection
                
                // MARK: Session History
                if !task.sessionsArray.isEmpty {
                    sessionHistorySection
                }
                
                // MARK: Actions
                actionsSection
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    viewModel.startEditing(task: task)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingEditTask) {
            EditTaskView(viewModel: viewModel)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Priority badge
                Text(task.priorityEmoji + " " + task.priorityLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.15))
                    .foregroundColor(priorityColor)
                    .cornerRadius(8)
                
                Spacer()
                
                // Completion status
                Text(task.isCompleted ? "✅ Completed" : "⏳ In Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(task.titleUnwrapped)
                .font(.title2)
                .fontWeight(.bold)
                .strikethrough(task.isCompleted)
            
            // Created date
            if let created = task.createdAt {
                Text("Created \(created.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DETAILS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if !task.notesUnwrapped.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Notes", systemImage: "note.text")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(task.notesUnwrapped)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            if let due = task.dueDate {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Due Date", systemImage: "calendar")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(due.formatted(date: .complete, time: .omitted))
                        .font(.body)
                        .foregroundColor(
                            due < Date() && !task.isCompleted
                            ? .red : .secondary
                        )
                    
                    if due < Date() && !task.isCompleted {
                        Text("⚠️ Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - Focus Stats
    private var focusStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FOCUS STATS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                // Pomodoros completed
                statCard(
                    value: "\(viewModel.sessionCount(for: task))",
                    label: "Pomodoros",
                    icon: "🍅"
                )
                
                Divider().frame(height: 50)
                
                // Total focus time
                statCard(
                    value: viewModel.focusTime(for: task),
                    label: "Focus Time",
                    icon: "⏱️"
                )
                
                Divider().frame(height: 50)
                
                // Sessions total
                statCard(
                    value: "\(task.sessionsArray.count)",
                    label: "Sessions",
                    icon: "📊"
                )
            }
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        }
    }
    
    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Session History
    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SESSION HISTORY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(task.sessionsArray.reversed()) { session in
                    HStack {
                        Text(session.sessionTypeLabel)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(session.durationLabel)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let start = session.startTime {
                                Text(start.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        Image(systemName: session.wasCompleted
                              ? "checkmark.circle.fill"
                              : "xmark.circle.fill")
                            .foregroundColor(
                                session.wasCompleted ? .green : .red
                            )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Toggle complete
            Button {
                viewModel.toggleComplete(task: task)
                dismiss()
            } label: {
                Label(
                    task.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                    systemImage: task.isCompleted
                        ? "arrow.uturn.backward.circle"
                        : "checkmark.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(task.isCompleted
                             ? Color.gray.opacity(0.15)
                             : Color.green)
                .foregroundColor(task.isCompleted ? .primary : .white)
                .cornerRadius(12)
            }
            
            // Delete
            Button(role: .destructive) {
                if let index = viewModel.tasks.firstIndex(of: task) {
                    viewModel.deleteTask(at: IndexSet(integer: index))
                    dismiss()
                }
            } label: {
                Label("Delete Task", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
        }
    }
    
    // Priority color helper
    private var priorityColor: Color {
        switch task.priority {
        case 0: return .green
        case 1: return .orange
        case 2: return .red
        default: return .orange
        }
    }
}
