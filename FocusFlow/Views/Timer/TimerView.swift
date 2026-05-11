// TimerView.swift
// The main Pomodoro timer screen.

import SwiftUI
import CoreData

struct TimerView: View {
    
    @StateObject private var viewModel: TimerViewModel
    @Environment(\.managedObjectContext) private var context
    @State private var showSettings = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(
            wrappedValue: TimerViewModel(context: context)
        )
    }
    
    // Ring color based on session type
    var ringColor: Color {
        switch viewModel.sessionType {
        case .work:       return .red
        case .shortBreak: return .green
        case .longBreak:  return .blue
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    
                    // MARK: Session dots
                    sessionDotsView
                    
                    // MARK: Circular ring
                    CircularProgressRing(
                        progress: viewModel.progress,
                        timeString: viewModel.timeString,
                        sessionLabel: viewModel.sessionType.label,
                        sessionEmoji: viewModel.sessionType.emoji,
                        ringColor: ringColor
                    )
                    
                    // MARK: Control buttons
                    controlButtonsView
                    
                    // MARK: Task selector
                    taskSelectorView
                    
                    // MARK: Session info
                    sessionInfoView
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Focus Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $viewModel.showTaskPicker) {
                TaskPickerView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Session Dots
    private var sessionDotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.totalSessions, id: \.self) { index in
                Circle()
                    .fill(index < viewModel.currentSession - 1
                          ? ringColor
                          : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .scaleEffect(
                        index == viewModel.currentSession - 1
                        ? 1.3 : 1.0
                    )
                    .animation(.spring(),
                               value: viewModel.currentSession)
            }
        }
    }
    
    // MARK: - Control Buttons
    private var controlButtonsView: some View {
        HStack(spacing: 24) {
            
            Button(action: viewModel.reset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 56, height: 56)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            
            Button {
                if viewModel.timerState == .running {
                    viewModel.pause()
                } else {
                    viewModel.start()
                }
            } label: {
                Image(systemName: viewModel.timerState == .running
                      ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(ringColor)
                    .clipShape(Circle())
                    .shadow(color: ringColor.opacity(0.4),
                            radius: 12, y: 6)
            }
            .scaleEffect(
                viewModel.timerState == .running ? 1.05 : 1.0
            )
            .animation(.spring(response: 0.3),
                       value: viewModel.timerState)
            
            Button(action: viewModel.skip) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 56, height: 56)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Task Selector
    private var taskSelectorView: some View {
        Button {
            viewModel.showTaskPicker = true
        } label: {
            HStack {
                Image(systemName: "link")
                    .font(.subheadline)
                Text(viewModel.selectedTask?.titleUnwrapped
                     ?? "Link to a task (optional)")
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(
                viewModel.selectedTask != nil
                ? ringColor : .secondary
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Session Info
    private var sessionInfoView: some View {
        VStack(spacing: 8) {
            Text("Session \(viewModel.currentSession) of \(viewModel.totalSessions)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(viewModel.isWorkSession
                 ? "Stay focused — you've got this! 💪"
                 : "Take a proper break, step away 🧘")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
