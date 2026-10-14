/// A partial update to a task's editable fields. `nil` means "leave unchanged".
public struct TaskChanges: Hashable, Sendable {
    public var title: String?
    public var notes: String?
    public var category: TaskCategory?
    public var priority: TaskPriority?
    public var status: TaskStatus?

    public init(
        title: String? = nil,
        notes: String? = nil,
        category: TaskCategory? = nil,
        priority: TaskPriority? = nil,
        status: TaskStatus? = nil
    ) {
        self.title = title
        self.notes = notes
        self.category = category
        self.priority = priority
        self.status = status
    }

    /// Whether the change set contains no edits.
    public var isEmpty: Bool {
        title == nil && notes == nil && category == nil && priority == nil && status == nil
    }
}
