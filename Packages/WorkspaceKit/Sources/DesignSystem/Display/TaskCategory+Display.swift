import Foundation
import WorkspaceDomain

extension TaskCategory {
    /// Localised category name.
    public var displayName: String {
        switch self {
        case .development: String(localized: "Development", bundle: .module)
        case .testing: String(localized: "Testing", bundle: .module)
        case .design: String(localized: "Design", bundle: .module)
        case .operations: String(localized: "Operations", bundle: .module)
        }
    }

    /// SF Symbol representing the category.
    public var symbolName: String { defaultAppearance.glyph }
}
