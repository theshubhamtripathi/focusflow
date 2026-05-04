// AddTaskView.swift
// Bottom sheet form for creating a new task.
// WHY a sheet and not a NavigationLink?
// Sheets are for quick actions that don't need their own
// navigation history. Creating a task is in-and-out — a sheet
// feels right. Navigation links are for drilling into detail.

import SwiftUI

struct AddTaskView: View {
    
    // WHY @ObservedObject here?
    // We pass the same TaskViewModel from the parent.
    // All the form fields (@Published vars) live in the ViewModel
    // so when the user types, the ViewModel updates in real time.
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                
                // MARK: - Title
                Section {
                    TextField("Task title", text: $viewModel.newTaskTitle)
                        .font(.body)
                    
                    TextField("Notes (optional)", text: $viewModel.newTaskNotes, axis: .vertical)
                        .lineLimit(3)
                        .font(.body)
                } header: {
                    Text("TASK DETAILS")
                }
                
                // MARK: - Priority
                Section {
                    Picker("Priority", selection: $viewModel.newTaskPriority) {
                        Text("🟢 Low").tag(Int16(0))
                        Text("🟡 Medium").tag(Int16(1))
                        Text("🔴 High").tag(Int16(2))
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("PRIORITY")
                }
                
                // MARK: - Due Date
                Section {
                    Toggle("Set due date", isOn: $viewModel.showDueDate)
                    
                    if viewModel.showDueDate {
                        DatePicker("Due date",
                                   selection: $viewModel.newTaskDueDate,
                                   displayedComponents: .date)
                    }
                } header: {
                    Text("DUE DATE")
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                // Cancel button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                
                // Add button — disabled if title is empty
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        viewModel.addTask()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.newTaskTitle.trimmingCharacters(
                        in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
