import SwiftUI

extension Color {
    static let rose       = Color(hex: "#A83858")
    static let sage       = Color(hex: "#3D7A5A")
    static let sageLight  = Color(hex: "#D0E8DA")
    static let roseLight  = Color(hex: "#EDD5DC")
    static let charcoal   = Color(hex: "#1A2738")
    static let slateMid   = Color(hex: "#556070")
    static let warmWhite  = Color(hex: "#F0EEEC")
    static let appBorder  = Color(hex: "#AEA49A")
    static let gold       = Color(hex: "#8C6A3A")

    // Phase colours
    static let phaseRed    = Color(hex: "#C2566A")  // Menstruation
    static let phaseGreen  = Color(hex: "#6A9E7F")  // Follicular
    static let phaseGold   = Color(hex: "#B8936A")  // Ovulation
    static let phasePurple = Color(hex: "#7B6FA0")  // Luteal

    // Severity colours
    static func severityColor(for level: Int) -> Color {
        switch level {
        case 1, 2: return Color(hex: "#6A9E7F")
        case 3:    return Color(hex: "#8AAE6A")
        case 4:    return Color(hex: "#B8BE6A")
        case 5:    return Color(hex: "#C8A96E")
        case 6:    return Color(hex: "#C8966E")
        case 7:    return Color(hex: "#C87A6E")
        case 8:    return Color(hex: "#C8626E")
        case 9:    return Color(hex: "#A83050")
        case 10:   return Color(hex: "#801020")
        default:   return Color.gray
        }
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Phase Color Lookup
func phaseColor(for phase: CyclePhase) -> Color {
    switch phase {
    case .menstruation: return .phaseRed
    case .follicular:   return .phaseGreen
    case .ovulation:    return .phaseGold
    case .luteal:       return .phasePurple
    }
}
