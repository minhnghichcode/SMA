import SwiftUI

struct ThemeColors {
    // Primary colors
    static let primary = Color(hex: "#B71C24")       // Đỏ HDBank (slightly darker for better contrast)
    static let primaryText = Color.white

    // Secondary colors
    static let secondary = Color(hex: "#F2F4F7") 
    static let secondaryText = Color(hex: "#1F2937") // Dark gray for readable text on yellow

    // Background colors
    static let background = Color(hex: "#FFFFFF")
    static let inputBackground = Color(hex: "#FFFFFF") // Slight bluish gray for modern look
    static let border = Color(hex: "#E6E6E9")

    // Accent colors
    static let accent = Color(hex: "#1F2937") // dark slate
}

// Extension hỗ trợ hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
extension Color {
    static let themePrimary = ThemeColors.primary
    static let themePrimaryText = ThemeColors.primaryText
    static let themeSecondary = ThemeColors.secondary
    static let themeSecondaryText = ThemeColors.secondaryText
    static let themeBackground = ThemeColors.background
    static let themeInputBackground = ThemeColors.inputBackground
    static let themeBorder = ThemeColors.border
    static let themeAccent = ThemeColors.accent
}