// AppTheme.swift
// Central design system for FocusFlow.

import SwiftUI

// MARK: - App Colors
struct AppColors {
    static let primary = Color("AccentColor")
    static let focusRed = Color.red
    static let breakGreen = Color.green
    static let longBreakBlue = Color.blue
    
    static let cardBackground = Color(
        UIColor.secondarySystemBackground
    )
    static let rowBackground = Color(
        UIColor.tertiarySystemBackground
    )
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let separator = Color(UIColor.separator)
    
    static let priorityLow = Color.green
    static let priorityMedium = Color.orange
    static let priorityHigh = Color.red
    
    static let streakFire = Color.orange
    static let heatmapEmpty = Color.gray.opacity(0.15)
    static let heatmapLight = Color.green.opacity(0.3)
    static let heatmapMedium = Color.green.opacity(0.55)
    static let heatmapStrong = Color.green.opacity(0.75)
    static let heatmapMax = Color.green
}

// MARK: - App Typography
// WHY only Font types here?
// Font is a value type that works everywhere.
// foregroundColor is a ViewModifier — it belongs in Views,
// not in a shared typography system.
struct AppTypography {
    static let timerDisplay = Font.system(
        size: 56, weight: .thin, design: .monospaced
    )
    static let heroNumber = Font.system(
        size: 64, weight: .bold, design: .rounded
    )
    static let sectionHeader = Font.caption
    static let cardTitle = Font.headline
    static let bodyText = Font.body
    static let caption = Font.caption
}

// MARK: - App Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - App Corner Radius
struct AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - View Modifiers
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppRadius.large)
    }
}

struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTypography.sectionHeader)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.secondaryText)
            .textCase(.uppercase)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderModifier())
    }
}
