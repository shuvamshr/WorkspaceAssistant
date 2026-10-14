import Foundation

/// The three columns of the Board layout.
public enum BoardColumn: String, CaseIterable, Identifiable, Sendable {
    case priority, backlog, done

    public var id: String { rawValue }

    /// Localised column title.
    public var title: String {
        switch self {
        case .priority: String(localized: "Priority")
        case .backlog: String(localized: "Backlog")
        case .done: String(localized: "Done")
        }
    }

    /// The column a task currently sits in.
    static func of(_ task: TaskItem) -> BoardColumn {
        if task.isDone { return .done }
        return task.isHighPriority ? .priority : .backlog
    }

    /// The field changes that move a task into this column.
    var changes: TaskChanges {
        switch self {
        case .priority: TaskChanges(priority: .high, status: .open)
        case .backlog: TaskChanges(priority: .normal, status: .open)
        case .done: TaskChanges(status: .done)
        }
    }
}
