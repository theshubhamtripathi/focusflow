// WeeklyBarChart.swift
// Bar chart showing daily focus minutes for the past week.
// WHY build our own and not use Swift Charts?
// Swift Charts is great but requires iOS 16+.
// This custom version works on all iOS 15+ devices and
// teaches you GeometryReader — a fundamental SwiftUI concept.

import SwiftUI

struct WeeklyBarChart: View {
    
    let data: [DayData]
    let maxMinutes: Int
    
    private let dayLetters = ["S","M","T","W","T","F","S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("LAST 7 DAYS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 4) {
                        
                        // Minutes label (only if > 0)
                        if day.minutes > 0 {
                            Text("\(day.minutes)m")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        
                        // Bar
                        // WHY GeometryReader?
                        // We need the parent's height to scale bars proportionally.
                        // GeometryReader gives us the exact available size at runtime.
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        day.isToday
                                        ? Color.blue
                                        : day.hadActivity
                                            ? Color.green.opacity(0.7)
                                            : Color.gray.opacity(0.2)
                                    )
                                    .frame(
                                        height: max(
                                            4, // minimum bar height
                                            geo.size.height *
                                            CGFloat(day.minutes) /
                                            CGFloat(maxMinutes)
                                        )
                                    )
                            }
                        }
                        .frame(height: 80)
                        
                        // Day letter
                        Text(shortDayLetter(for: day.date))
                            .font(.caption2)
                            .foregroundColor(
                                day.isToday ? .blue : .secondary
                            )
                            .fontWeight(day.isToday ? .bold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    private func shortDayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // single letter
        return formatter.string(from: date)
    }
}
