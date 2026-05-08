// TaskPickerView.swift
// Sheet for picking which task to focus on during the timer.

import SwiftUI
import CoreData

struct TaskPickerView: View {
    
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var tasks: [Task] = []
    
    var body: some View {
        NavigationView {
            List {
                // No task option
                Button {
                    viewModel.selectedTask = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("No task")
                            .foregroundColor(.primary)
                        Spacer()
                        if viewModel.selectedTask == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Incomplete tasks
                ForEach(tasks.filter { !$0.isCompleted }) { task in
                    Button {
                        viewModel.selectedTask = task
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.titleUnwrapped)
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                
                                Text("\(task.totalFocusMinutes) min focused")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Text(task.priorityEmoji)
                                
                                if viewModel.selectedTask == task {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                fetchTasks()
            }
        }
    }
    
    private func fetchTasks() {
        let request = NSFetchRequest<Task>(entityName: "Task")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)
        ]
        request.predicate = NSPredicate(format: "isCompleted == NO")
        tasks = (try? context.fetch(request)) ?? []
    }
}
