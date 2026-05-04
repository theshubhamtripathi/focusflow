// TaskListView.swift
// The main task list screen.

import SwiftUI
import CoreData

struct TaskListView: View {
    
    // WHY @StateObject and not @ObservedObject?
    // @StateObject means THIS view OWNS the ViewModel.
    // SwiftUI creates it once and keeps it alive as long
    // as this view exists.
    // @ObservedObject is for ViewModels passed IN from outside.
    // Rule of thumb: the view that creates the ViewModel uses
    // @StateObject. Every other view uses @ObservedObject.
    @StateObject private var viewModel: TaskViewModel
    
    // Pull the CoreData context from the environment
    // (we injected it in FocusFlowApp.swift on Day 1)
    @Environment(\.managedObjectContext) private var context
    
    init(context: NSManagedObjectContext) {
        // WHY _viewModel with underscore?
        // When initialising a @StateObject, you access the
        // underlying StateObject wrapper with underscore prefix.
        // This is a SwiftUI requirement.
        _viewModel = StateObject(wrappedValue: TaskViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.tasks.isEmpty {
                    // MARK: Empty state
                    emptyStateView
                } else {
                    // MARK: Task list
                    taskListView
                }
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            // Sheet presentation
            .sheet(isPresented: $viewModel.showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Task List
    private var taskListView: some View {
        List {
            // Progress header
            if !viewModel.tasks.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(viewModel.completionPercentage))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(
                                        width: geo.size.width * viewModel.completionPercentage / 100,
                                        height: 8
                                    )
                                    .animation(.spring(), value: viewModel.completionPercentage)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(viewModel.completedTasks.count) of \(viewModel.tasks.count) tasks complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Incomplete tasks
            if !viewModel.incompleteTasks.isEmpty {
                Section("TO DO (\(viewModel.incompleteTasks.count))") {
                    ForEach(viewModel.incompleteTasks) { task in
                        TaskRowView(task: task) {
                            viewModel.toggleComplete(task: task)
                        }
                    }
                    .onDelete { offsets in
                        // Map incomplete task offsets back to full array
                        let tasksToDelete = offsets.map {
                            viewModel.incompleteTasks[$0]
                        }
                        tasksToDelete.forEach { task in
                            if let index = viewModel.tasks.firstIndex(of: task) {
                                viewModel.deleteTask(at: IndexSet(integer: index))
                            }
                        }
                    }
                }
            }
            
            // Completed tasks
            if !viewModel.completedTasks.isEmpty {
                Section("COMPLETED (\(viewModel.completedTasks.count))") {
                    ForEach(viewModel.completedTasks) { task in
                        TaskRowView(task: task) {
                            viewModel.toggleComplete(task: task)
                        }
                    }
                    .onDelete { offsets in
                        let tasksToDelete = offsets.map {
                            viewModel.completedTasks[$0]
                        }
                        tasksToDelete.forEach { task in
                            if let index = viewModel.tasks.firstIndex(of: task) {
                                viewModel.deleteTask(at: IndexSet(integer: index))
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No tasks yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tap + to add your first task")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.showingAddTask = true
            } label: {
                Label("Add Task", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}
