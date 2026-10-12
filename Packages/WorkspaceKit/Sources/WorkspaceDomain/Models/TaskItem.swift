import Foundation

/// A task in the workspace. Value type; mutate it only through `WorkspaceCommand`s.
public struct TaskItem: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var category: TaskCategory
    public var priority: TaskPriority
    public var status: TaskStatus
    public var origin: TaskOrigin
    /// Custom appearance; `nil` means "derive from category".
    public var appearance: TileAppearance?
    public var steps: [TaskStep]
    public var createdAt: Date
    /// Fractional ordering key; lower sorts first.
    public var sortIndex: Double

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        category: TaskCategory,
        priority: TaskPriority = .normal,
        status: TaskStatus = .open,
        origin: TaskOrigin = .user,
        appearance: TileAppearance? = nil,
        steps: [TaskStep] = [],
        createdAt: Date = .now,
        sortIndex: Double = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.category = category
        self.priority = priority
        self.status = status
        self.origin = origin
        self.appearance = appearance
        self.steps = steps
        self.createdAt = createdAt
        self.sortIndex = sortIndex
    }

    /// The appearance to draw: the custom one, or the category default.
    public var resolvedAppearance: TileAppearance { appearance ?? category.defaultAppearance }

    /// Convenience for `priority == .high`.
    public var isHighPriority: Bool { priority == .high }

    /// Convenience for `status == .done`.
    public var isDone: Bool { status == .done }

    /// Number of completed checklist steps.
    public var completedStepCount: Int { steps.count(where: \.isDone) }

    /// Fraction of steps completed, or `nil` when the task has no steps.
    public var stepProgress: Double? {
        steps.isEmpty ? nil : Double(completedStepCount) / Double(steps.count)
    }
}
