import SwiftUI

// MARK: - Color Tokens

enum AppColors {
    /// 青色 — 主色调 #0AB5C7
    static let primary = Color(red: 0.04, green: 0.71, blue: 0.78)
    /// 浅青背景
    static let primaryLight = Color(red: 0.04, green: 0.71, blue: 0.78).opacity(0.12)

    /// 达标绿
    static let accentGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    /// 超标红
    static let accentRed = Color(red: 0.94, green: 0.27, blue: 0.22)
    /// 蓝色强调
    static let accentBlue = Color(red: 0.00, green: 0.48, blue: 1.00)

    /// 卡片背景 (自动适配深浅色)
    static let cardBackground = Color(.systemBackground)
    /// 页面背景
    static let surfaceBackground = Color(.systemGroupedBackground)

    // Meal type accent colors
    static let breakfast = Color(red: 1.00, green: 0.76, blue: 0.03)
    static let lunch = Color.orange
    static let dinner = Color(red: 0.56, green: 0.27, blue: 0.68)
    static let snack = Color(white: 0.50)

    static func mealColor(_ meal: MealType) -> Color {
        switch meal {
        case .breakfast: breakfast
        case .lunch: lunch
        case .dinner: dinner
        case .snack: snack
        }
    }
}

// MARK: - Radius Tokens

enum AppRadius {
    static let card: CGFloat = 20
    static let chip: CGFloat = 12
    static let button: CGFloat = 12
    static let small: CGFloat = 8
}

// MARK: - Shadow Token

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    static let card = AppShadow(
        color: .black.opacity(0.04),
        radius: 8,
        y: 2
    )

    static let elevated = AppShadow(
        color: .black.opacity(0.08),
        radius: 16,
        y: 4
    )
}

extension View {
    func appCardShadow() -> some View {
        shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, y: AppShadow.card.y)
    }

    func appElevatedShadow() -> some View {
        shadow(color: AppShadow.elevated.color, radius: AppShadow.elevated.radius, y: AppShadow.elevated.y)
    }
}

// MARK: - Haptic Feedback

enum Haptic {
    static func light() {
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func medium() {
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func success() {
        #if !targetEnvironment(simulator)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if !targetEnvironment(simulator)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}
