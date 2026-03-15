import SwiftUI

extension Color {
    static let sgTeal = Color(red: 0.55, green: 0.58, blue: 0.98)
    static let sgTealDark = Color(red: 0.38, green: 0.40, blue: 0.80)
    static let sgYellow = Color(red: 1.00, green: 0.82, blue: 0.13)
    static let sgBackground = Color(red: 0.06, green: 0.038, blue: 0.150)

    static let scrollGremlinPrimary = sgTeal
}

extension UIColor {
    static let scrollGremlinPrimary = UIColor(red: 0.55, green: 0.58, blue: 0.98, alpha: 1)
}

enum SGGradient {
    static var brand: LinearGradient {
        LinearGradient(
            colors: [Color.sgTeal, Color(red: 0.40, green: 0.42, blue: 0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accent: LinearGradient {
        LinearGradient(
            colors: [Color.sgYellow, Color(red: 0.96, green: 0.68, blue: 0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var pastelHero: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.72, blue: 0.98),
                Color(red: 0.62, green: 0.55, blue: 0.98),
                Color(red: 0.92, green: 0.65, blue: 0.88),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cardSheen(opacity: Double = 0.06) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.62, green: 0.65, blue: 1.00).opacity(opacity), location: 0),
                .init(color: Color.clear, location: 0.65),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension AppColorScheme {
    var swiftUIColorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}
