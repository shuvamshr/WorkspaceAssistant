import FoundationModels
import WorkspaceDomain

/// Task category as a constrained model argument.
@Generable
enum CategoryArgument: String, CaseIterable {
    case development, testing, design, operations

    var domain: TaskCategory { TaskCategory(rawValue: rawValue) ?? .development }
}

/// Task priority as a constrained model argument.
@Generable
enum PriorityArgument: String, CaseIterable {
    case normal, high

    var domain: TaskPriority { self == .high ? .high : .normal }
}

/// Board layout as a constrained model argument.
@Generable
enum LayoutArgument: String, CaseIterable {
    case grid, list, focus, board

    var domain: BoardLayout { BoardLayout(rawValue: rawValue) ?? .grid }
}

/// Accent theme as a constrained model argument.
@Generable
enum AccentArgument: String, CaseIterable {
    case indigo, blue, teal, green, orange, red, purple

    var domain: AccentTheme { AccentTheme(rawValue: rawValue) ?? .indigo }
}

/// Tile colour as a constrained model argument.
@Generable
enum TileColorArgument: String, CaseIterable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, gray

    var domain: TileColor { TileColor(rawValue: rawValue) ?? .blue }
}
