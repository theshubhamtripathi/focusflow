// HeatmapView.swift
// GitHub-style contribution heatmap showing 12 weeks of activity.
//
// WHY a heatmap?
// It gives users an instant visual of their consistency over time.
// Green squares = active days. Empty = missed days.
// It's deeply motivating because patterns are immediately visible.

import SwiftUI

struct HeatmapView: View {
    
    let data: [DayData]
    // 84 days split into 12 columns of 7 rows
    // WHY this layout?
    // Each column = one week (7 days).
    // Reading left to right = oldest to newest week.
    // This is the exact same layout as GitHub contributions.
    
    private let columns = 12
    private let rows = 7
    private let cellSize: CGFloat = 18
    private let cellSpacing: CGFloat = 3
    
    // Split 84 days into weeks (columns of 7)
    private var weeks: [[DayData]] {
        stride(from: 0, to: data.count, by: 7).map {
            Array(data[$0..<min($0 + 7, data.count)])
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Day labels (M T W T F S S)
            HStack(spacing: cellSpacing) {
                // Empty space for alignment
                ForEach(0..<columns, id: \.self) { _ in
                    Color.clear.frame(width: cellSize)
                }
            }
            
            // Main grid
            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: cellSpacing) {
                        ForEach(week) { day in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(cellColor(for: day))
                                .frame(width: cellSize, height: cellSize)
                                .overlay(
                                    // Highlight today with a border
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(
                                            day.isToday
                                                ? Color.primary
                                                : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ForEach(0...4, id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(intensityColor(intensity))
                        .frame(width: 12, height: 12)
                }
                
                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Cell Color
    // WHY green shades?
    // Green = growth, progress. Same reason GitHub uses green.
    // The 5 intensities (0-4) map to how many minutes of focus
    // the user had that day.
    private func cellColor(for day: DayData) -> Color {
        intensityColor(day.intensity)
    }
    
    private func intensityColor(_ intensity: Int) -> Color {
        switch intensity {
        case 0: return Color.gray.opacity(0.15)  // no activity
        case 1: return Color.green.opacity(0.3)  // 1-25 min
        case 2: return Color.green.opacity(0.5)  // 26-50 min
        case 3: return Color.green.opacity(0.75) // 51-75 min
        default: return Color.green              // 75+ min
        }
    }
}
