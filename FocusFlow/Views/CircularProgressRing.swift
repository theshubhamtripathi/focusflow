// CircularProgressRing.swift
// The animated circular countdown ring.
// WHY a separate component?
// This is a pure visual component with its own drawing logic.
// Keeping it separate means we can reuse it anywhere in the app.

import SwiftUI

struct CircularProgressRing: View {
    
    var progress: Double      // 0.0 to 1.0
    var timeString: String    // "25:00"
    var sessionLabel: String  // "Focus Time"
    var sessionEmoji: String  // "🍅"
    var ringColor: Color      // changes per session type
    
    // Ring dimensions
    private let ringWidth: CGFloat = 20
    private let size: CGFloat = 260
    
    var body: some View {
        ZStack {
            
            // MARK: Background ring (always full, gray)
            // WHY two circles?
            // The gray circle is the "track" — always full.
            // The colored circle sits on top and shrinks as time runs out.
            // Together they create the progress ring effect.
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: ringWidth)
                .frame(width: size, height: size)
            
            // MARK: Progress ring (colored, drains over time)
            Circle()
                .trim(from: 0, to: progress)
                // WHY .trim(from: 0, to: progress)?
                // .trim cuts the circle stroke to only draw a fraction.
                // progress = 1.0 → full circle drawn
                // progress = 0.5 → half circle drawn
                // progress = 0.0 → nothing drawn
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round  // rounded ends look premium
                    )
                )
                .frame(width: size, height: size)
                // WHY rotationEffect?
                // By default .trim starts at 3 o'clock (right side).
                // We rotate -90° so it starts at 12 o'clock (top).
                .rotationEffect(.degrees(-90))
                // WHY .animation here?
                // Without this, the ring jumps every second.
                // With it, the ring smoothly shrinks each tick.
                .animation(.linear(duration: 1), value: progress)
            
            // MARK: Inner content
            VStack(spacing: 8) {
                Text(sessionEmoji)
                    .font(.system(size: 40))
                
                Text(timeString)
                    .font(.system(size: 56, weight: .thin, design: .monospaced))
                    // WHY .monospaced?
                    // Regular fonts have different widths per character.
                    // "1" is narrower than "8". This causes the timer to
                    // shift left/right every second as digits change.
                    // Monospaced = every digit same width = stable display.
                    .foregroundColor(.primary)
                
                Text(sessionLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
    }
}
