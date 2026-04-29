import SwiftUI

enum Theme {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let sidebarBackground = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let cardBackground = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let stroke = Color.white.opacity(0.06)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    static let accentGradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.55, blue: 0.30),
                 Color(red: 1.00, green: 0.30, blue: 0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let focusGradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.45, blue: 0.35),
                 Color(red: 0.95, green: 0.25, blue: 0.50)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let breakGradient = LinearGradient(
        colors: [Color(red: 0.35, green: 0.75, blue: 0.95),
                 Color(red: 0.40, green: 0.55, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let longBreakGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.85, blue: 0.55),
                 Color(red: 0.30, green: 0.70, blue: 0.65)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
