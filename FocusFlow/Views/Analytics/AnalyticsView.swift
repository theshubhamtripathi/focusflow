// AnalyticsView.swift
// Analytics dashboard with Swift Charts.
//
// WHY Swift Charts and not a custom chart like Day 5?
// Swift Charts (iOS 16+) is Apple's official charting framework.
// It's declarative, accessible, and handles animations
// automatically. Using it shows you know modern Apple APIs.

import SwiftUI
import Charts
import CoreData

struct AnalyticsView: View {
    
    @StateObject private var viewModel: AnalyticsViewModel
    @Environment(\.managedObjectContext) private var context
    @State private var selectedRange: ChartRange = .week
    
    enum ChartRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(
            wrappedValue: AnalyticsViewModel(context: context)
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: Summary cards
                    summaryCardsView
                    
                    // MARK: Focus time chart
                    focusTimeChartCard
                    
                    // MARK: Task completion donut
                    taskCompletionCard
                    
                    // MARK: Hourly pattern
                    hourlyPatternCard
                    
                    // MARK: Insights
                    insightsCard
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - Summary Cards
    private var summaryCardsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                
                summaryCard(
                    title: "Avg Daily",
                    value: "\(viewModel.averageDailyMinutes)m",
                    icon: "⏱️",
                    color: .blue
                )
                
                summaryCard(
                    title: "Peak Hour",
                    value: viewModel.mostProductiveHour,
                    icon: "⚡",
                    color: .orange
                )
                
                summaryCard(
                    title: "Best Day",
                    value: viewModel.bestDay,
                    icon: "🏆",
                    color: .yellow
                )
                
                summaryCard(
                    title: "Completion",
                    value: "\(Int(viewModel.taskCompletionRate))%",
                    icon: "✅",
                    color: .green
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func summaryCard(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 110)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Focus Time Chart
    private var focusTimeChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Focus Time")
                    .font(.headline)
                Spacer()
                // Range picker
                Picker("Range", selection: $selectedRange) {
                    ForEach(ChartRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            
            // Swift Charts bar chart
            // WHY Chart { ForEach }?
            // This is Swift Charts' declarative syntax.
            // Each BarMark = one bar. x and y take KeyValuePairs
            // that map your data to chart axes automatically.
            let chartData = selectedRange == .week
                ? viewModel.weeklyData
                : viewModel.monthlyData
            
            Chart {
                ForEach(chartData) { point in
                    BarMark(
                        x: .value("Day", point.label),
                        y: .value("Minutes", point.minutes)
                    )
                    .foregroundStyle(
                        point.minutes > 0
                        ? Color.blue.gradient
                        : Color.gray.opacity(0.2).gradient
                    )
                    .cornerRadius(6)
                    // WHY .annotation?
                    // Shows the exact number above each bar.
                    // Users can read precise values without
                    // trying to estimate from the axis.
                    .annotation(position: .top) {
                        if point.minutes > 0 {
                            Text("\(point.minutes)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Average line
                // WHY RuleMark?
                // A horizontal reference line showing the average
                // helps users see if today was above or below
                // their typical performance.
                if selectedRange == .week {
                    RuleMark(
                        y: .value(
                            "Average",
                            viewModel.averageDailyMinutes
                        )
                    )
                    .lineStyle(StrokeStyle(
                        lineWidth: 1,
                        dash: [4]
                    ))
                    .foregroundStyle(Color.orange)
                    .annotation(position: .trailing) {
                        Text("avg")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)m")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Task Completion Donut
    private var taskCompletionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Task Completion")
                .font(.headline)
            
            if viewModel.completionData.isEmpty {
                Text("No tasks yet — add some in the Tasks tab!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                HStack(spacing: 24) {
                    
                    // Donut chart using Swift Charts
                    Chart(viewModel.completionData) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(
                            item.label == "Completed"
                            ? Color.green : Color.blue
                        )
                        .cornerRadius(4)
                    }
                    .frame(width: 130, height: 130)
                    // Centre label overlay
                    .overlay {
                        VStack(spacing: 2) {
                            Text("\(Int(viewModel.taskCompletionRate))%")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("done")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.completionData) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(
                                        item.label == "Completed"
                                        ? Color.green : Color.blue
                                    )
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.label)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("\(item.count) tasks")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Hourly Pattern
    private var hourlyPatternCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Peak Focus Hours")
                    .font(.headline)
                Text("When do you focus best?")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.hourlyData.allSatisfy({ $0.sessions == 0 }) {
                Text("Complete some Pomodoros to see your peak hours!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(viewModel.hourlyData) { item in
                    BarMark(
                        x: .value("Hour", item.hourLabel),
                        y: .value("Sessions", item.sessions)
                    )
                    .foregroundStyle(
                        item.sessions > 0
                        ? Color.purple.gradient
                        : Color.gray.opacity(0.15).gradient
                    )
                    .cornerRadius(4)
                }
                .frame(height: 160)
                .chartXAxis {
                    // WHY stride(by: 3)?
                    // Showing every hour label overlaps on small screens.
                    // Every 3 hours keeps it readable.
                    AxisMarks(values: stride(
                        from: 0,
                        to: viewModel.hourlyData.count,
                        by: 3
                    ).map { viewModel.hourlyData[$0].hourLabel }) {
                        AxisValueLabel()
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Insights
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("INSIGHTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                insightRow(
                    icon: "⚡",
                    text: "Peak focus hour: \(viewModel.mostProductiveHour)"
                )
                insightRow(
                    icon: "📅",
                    text: "Most productive day: \(viewModel.bestDay)"
                )
                insightRow(
                    icon: "⏱️",
                    text: "Daily average: \(viewModel.averageDailyMinutes) minutes"
                )
                insightRow(
                    icon: "✅",
                    text: "Task completion rate: \(Int(viewModel.taskCompletionRate))%"
                )
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func insightRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(8)
    }
}
