// EditTaskView.swift
// Edit an existing task — pre-filled form.
// WHY reuse the ViewModel form fields?
// We already have newTaskTitle, newTaskNotes etc in TaskViewModel.
// startEditing() pre-fills them with existing task data.
// This means EditTaskView looks almost identical to AddTaskView —
// zero code duplication.

import SwiftUI

struct EditTaskView: View {
    
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Task title", text: $viewModel.newTaskTitle)
                    TextField("Notes (optional)",
                              text: $viewModel.newTaskNotes,
                              axis: .vertical)
                        .lineLimit(3)
                } header: {
                    Text("TASK DETAILS")
                }
                
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
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateTask()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.newTaskTitle
                        .trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
