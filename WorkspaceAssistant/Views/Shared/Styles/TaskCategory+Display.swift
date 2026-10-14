import Foundation

extension TaskCategory {
    /// Localised category name.
    public var displayName: String {
        switch self {
        case .development: String(localized: "Development")
        case .testing: String(localized: "Testing")
        case .design: String(localized: "Design")
        case .operations: String(localized: "Operations")
        }
    }

    /// SF Symbol representing the category.
    public var symbolName: String { defaultAppearance.glyph }
}
