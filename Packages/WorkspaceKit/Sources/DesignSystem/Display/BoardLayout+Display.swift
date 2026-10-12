import Foundation
import WorkspaceDomain

extension BoardLayout {
    /// Localised layout name.
    public var displayName: String {
        switch self {
        case .grid: String(localized: "Grid", bundle: .module)
        case .list: String(localized: "List", bundle: .module)
        case .focus: String(localized: "Focus", bundle: .module)
        case .board: String(localized: "Board", bundle: .module)
        }
    }

    /// SF Symbol representing the layout.
    public var symbolName: String {
        switch self {
        case .grid: "square.grid.2x2"
        case .list: "list.bullet"
        case .focus: "scope"
        case .board: "rectangle.split.3x1"
        }
    }
}
