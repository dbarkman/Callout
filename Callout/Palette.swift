import CalloutCore
import SwiftUI

/// Colors that heat up as the round runs down. The app is always dark.
enum Palette {
    static let background = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let track = Color.white.opacity(0.08)
    static let done = Color(red: 1.0, green: 0.80, blue: 0.25)

    static func accent(_ phase: Phase) -> Color {
        switch phase {
        case .calm: Color(red: 0.25, green: 0.85, blue: 0.70)
        case .warning: Color(red: 1.0, green: 0.78, blue: 0.25)
        case .closing: Color(red: 1.0, green: 0.52, blue: 0.20)
        case .final: Color(red: 1.0, green: 0.25, blue: 0.25)
        }
    }

    /// How strongly the accent tints the background.
    static func glow(_ phase: Phase) -> Double {
        switch phase {
        case .calm: 0.0
        case .warning: 0.10
        case .closing: 0.18
        case .final: 0.30
        }
    }
}
