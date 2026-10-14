import Foundation

extension BoardLayout {
    /// Localised layout name.
    public var displayName: String {
        switch self {
        case .grid: String(localized: "Grid")
        case .list: String(localized: "List")
        case .focus: String(localized: "Focus")
        case .board: String(localized: "Board")
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
