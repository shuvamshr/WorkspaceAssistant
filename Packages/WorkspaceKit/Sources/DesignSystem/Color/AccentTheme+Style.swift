import SwiftUI
import WorkspaceDomain

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
        case .indigo: String(localized: "Indigo", bundle: .module)
        case .blue: String(localized: "Blue", bundle: .module)
        case .teal: String(localized: "Teal", bundle: .module)
        case .green: String(localized: "Green", bundle: .module)
        case .orange: String(localized: "Orange", bundle: .module)
        case .red: String(localized: "Red", bundle: .module)
        case .purple: String(localized: "Purple", bundle: .module)
        }
    }
}
