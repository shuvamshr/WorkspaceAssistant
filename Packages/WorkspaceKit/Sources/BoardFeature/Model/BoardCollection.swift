import DesignSystem
import Foundation
import WorkspaceDomain

/// A filtered view of the workspace: all tasks, priority, done, or a category.
public enum BoardCollection: Hashable, Sendable, Identifiable {
    case all
    case priority
    case done
    case category(TaskCategory)

    public var id: String {
        switch self {
        case .all: "all"
        case .priority: "priority"
        case .done: "done"
        case let .category(category): "category.\(category.rawValue)"
        }
    }

    /// Every collection, in sidebar order.
    public static var allCases: [BoardCollection] {
        [.all, .priority, .done] + TaskCategory.allCases.map(BoardCollection.category)
    }

    /// Localised title.
    public var title: String {
        switch self {
        case .all: String(localized: "Tasks", bundle: .module)
        case .priority: String(localized: "Priority", bundle: .module)
        case .done: String(localized: "Done", bundle: .module)
        case let .category(category): category.displayName
        }
    }

    /// SF Symbol for the collection.
    public var symbolName: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .priority: "star.fill"
        case .done: "checkmark.circle.fill"
        case let .category(category): category.symbolName
        }
    }

    /// Tile colour for the collection's glyph square.
    public var color: TileColor {
        switch self {
        case .all: .indigo
        case .priority: .orange
        case .done: .gray
        case let .category(category): category.defaultAppearance.color
        }
    }

    /// The category new tasks should default to when created from this collection.
    public var defaultCategory: TaskCategory {
        if case let .category(category) = self { return category }
        return .development
    }

    /// Whether a task belongs to this collection, ignoring done/open state.
    func contains(_ task: TaskItem) -> Bool {
        switch self {
        case .all, .done: true
        case .priority: task.isHighPriority
        case let .category(category): task.category == category
        }
    }

    /// Tasks shown for this collection in a layout. Only the Board layout and the Done collection show done tasks.
    func visibleTasks(_ tasks: [TaskItem], layout: BoardLayout) -> [TaskItem] {
        tasks.filter { task in
            guard contains(task) else { return false }
            switch self {
            case .done: return task.isDone
            default: return layout == .board || !task.isDone
            }
        }
    }
}
