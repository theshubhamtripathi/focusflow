// TaskListView.swift — updated for Day 4

import SwiftUI
import CoreData

struct TaskListView: View {
    
    @StateObject private var viewModel: TaskViewModel
    @Environment(\.managedObjectContext) private var context
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(
            wrappedValue: TaskViewModel(context: context)
        )
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.tasks.isEmpty {
                    emptyStateView
                } else {
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
            .sheet(isPresented: $viewModel.showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Task List
    private var taskListView: some View {
        List {
            // Progress header
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
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(
                                    width: geo.size.width *
                                        viewModel.completionPercentage / 100,
                                    height: 8
                                )
                                .animation(.spring(),
                                           value: viewModel.completionPercentage)
                        }
                    }
                    .frame(height: 8)
                    Text("\(viewModel.completedTasks.count) of \(viewModel.tasks.count) tasks complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // MARK: Filter bar
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.emoji + " " + filter.rawValue,
                                isSelected: viewModel.activeFilter == filter
                            ) {
                                viewModel.activeFilter = filter
                                viewModel.fetchTasks()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Incomplete tasks
            let incomplete = viewModel.filteredTasks.filter { !$0.isCompleted }
            if !incomplete.isEmpty {
                Section("TO DO (\(incomplete.count))") {
                    ForEach(incomplete) { task in
                        // WHY NavigationLink here?
                        // Tapping the row navigates to TaskDetailView.
                        // NavigationLink handles the push animation
                        // and back button automatically.
                        NavigationLink {
                            TaskDetailView(task: task, viewModel: viewModel)
                        } label: {
                            TaskRowView(task: task) {
                                viewModel.toggleComplete(task: task)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { incomplete[$0] }
                        toDelete.forEach { task in
                            if let index = viewModel.tasks.firstIndex(of: task) {
                                viewModel.deleteTask(
                                    at: IndexSet(integer: index)
                                )
                            }
                        }
                    }
                }
            }
            
            // Completed tasks
            let completed = viewModel.filteredTasks.filter { $0.isCompleted }
            if !completed.isEmpty {
                Section("COMPLETED (\(completed.count))") {
                    ForEach(completed) { task in
                        NavigationLink {
                            TaskDetailView(task: task, viewModel: viewModel)
                        } label: {
                            TaskRowView(task: task) {
                                viewModel.toggleComplete(task: task)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { completed[$0] }
                        toDelete.forEach { task in
                            if let index = viewModel.tasks.firstIndex(of: task) {
                                viewModel.deleteTask(
                                    at: IndexSet(integer: index)
                                )
                            }
                        }
                    }
                }
            }
            
            // Empty filter result
            if viewModel.filteredTasks.isEmpty && !viewModel.tasks.isEmpty {
                Section {
                    Text("No tasks match this filter")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
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

// MARK: - FilterChip
// WHY a separate struct?
// This small reusable button is used 5 times in the filter bar.
// Extracting it keeps the parent code clean and lets us style
// the selected vs unselected states in one place.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
