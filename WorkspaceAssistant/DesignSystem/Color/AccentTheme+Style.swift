import SwiftUI

extension AccentTheme {
    /// The system colour used as the app tint. Applied once at the root with `.tint(_:)`.
    public var color: Color {
        switch self {
        case .indigo: .indigo
        case .blue: .blue
        case .teal: .teal
        case .green: .green
        case .orange: .orange
        case .red: .red
        case .purple: .purple
        }
    }

    /// Localised theme name.
    public var displayName: String {
        switch self {
        case .indigo: String(localized: "Indigo")
        case .blue: String(localized: "Blue")
        case .teal: String(localized: "Teal")
        case .green: String(localized: "Green")
        case .orange: String(localized: "Orange")
        case .red: String(localized: "Red")
        case .purple: String(localized: "Purple")
        }
    }
}
