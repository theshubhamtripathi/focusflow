// StreakView.swift
// Main streak tracking screen.

import SwiftUI
import CoreData

struct StreakView: View {
    
    @StateObject private var viewModel: StreakViewModel
    @Environment(\.managedObjectContext) private var context
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(
            wrappedValue: StreakViewModel(context: context)
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: Streak hero card
                    streakHeroCard
                    
                    // MARK: Today's summary
                    todaySummaryCard
                    
                    // MARK: Weekly bar chart
                    WeeklyBarChart(
                        data: viewModel.weeklyData,
                        maxMinutes: viewModel.weeklyMax
                    )
                    .padding(.horizontal)
                    
                    // MARK: Heatmap
                    heatmapCard
                    
                    // MARK: All time stats
                    allTimeStatsCard
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Streaks")
            // Refresh data every time the tab is opened
            // WHY .onAppear?
            // The user might complete a Pomodoro session in the
            // Timer tab, then switch here. We reload so the stats
            // are always fresh.
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - Streak Hero Card
    private var streakHeroCard: some View {
        VStack(spacing: 16) {
            
            // Flame + number
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("🔥")
                    .font(.system(size: 56))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text(viewModel.currentStreak == 1 ? "day streak" : "day streak")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Motivational message
            Text(viewModel.streakMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Longest streak badge
            if viewModel.longestStreak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("Best: \(viewModel.longestStreak) days")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.15),
                    Color.red.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Today Summary
    private var todaySummaryCard: some View {
        HStack(spacing: 0) {
            
            todayStatItem(
                emoji: "⏱️",
                value: "\(viewModel.todayMinutes)m",
                label: "Today's Focus"
            )
            
            Divider().frame(height: 50)
            
            todayStatItem(
                emoji: "🍅",
                value: "\(viewModel.todaySessions)",
                label: "Pomodoros"
            )
            
            Divider().frame(height: 50)
            
            todayStatItem(
                emoji: viewModel.todaySessions > 0 ? "✅" : "⭕",
                value: viewModel.todaySessions > 0 ? "Done" : "Pending",
                label: "Today's Goal"
            )
        }
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func todayStatItem(
        emoji: String,
        value: String,
        label: String
    ) -> some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title2)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Heatmap Card
    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("ACTIVITY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Last 12 weeks")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // WHY ScrollView horizontal?
            // 12 weeks of cells is wider than most phones.
            // Horizontal scroll lets us show all data without
            // squishing the cells too small to see.
            ScrollView(.horizontal, showsIndicators: false) {
                HeatmapView(data: viewModel.heatmapData)
                    .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - All Time Stats
    private var allTimeStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("ALL TIME")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                allTimeStat(
                    value: viewModel.totalFocusHours,
                    label: "Total Focus",
                    color: .blue
                )
                
                Divider().frame(height: 50)
                
                allTimeStat(
                    value: "\(viewModel.totalSessions)",
                    label: "Sessions",
                    color: .red
                )
                
                Divider().frame(height: 50)
                
                allTimeStat(
                    value: "\(viewModel.longestStreak)d",
                    label: "Best Streak",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func allTimeStat(
        value: String,
        label: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
