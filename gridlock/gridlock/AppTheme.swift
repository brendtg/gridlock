import SwiftUI

enum AppTheme {
    static let primary        = Color(hex: "#3A7BD5")   // blue
    static let secondary      = Color(hex: "#F06292")   // pink
    static let background     = Color(hex: "#0F1923")   // deep navy
    static let surface        = Color(hex: "#1C2B3A")   // card/board background
    static let textPrimary    = Color(hex: "#FFFFFF")
    static let textSecondary  = Color(hex: "#A8B8C8")
    static let activeBoardHighlight = Color(hex: "#F06292")
    static let player1Color   = Color(hex: "#3A7BD5")
    static let player2Color   = Color(hex: "#F06292")
    static let wonBoardP1     = Color(hex: "#3A7BD5CC")
    static let wonBoardP2     = Color(hex: "#F06292CC")
    static let drawnBoard     = Color(hex: "#FFFFFF33")

    static func playerColor(_ player: Player) -> Color {
        player == .p1 ? player1Color : player2Color
    }

    static func wonBoardColor(_ player: Player) -> Color {
        player == .p1 ? wonBoardP1 : wonBoardP2
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

extension Font {
    static func sfRounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

enum AnimationConstants {
    static let zoomSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let routingDuration: Double = 0.6
    static let tokenPulse = Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
}
