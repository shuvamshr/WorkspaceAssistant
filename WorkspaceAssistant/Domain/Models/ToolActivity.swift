import Foundation

/// A record of one tool call by the assistant, rendered as an action block.
public struct ToolActivity: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let kind: ToolKind
    public let parameters: [ToolParameter]
    public let outcome: ToolOutcome
    /// Tasks the call referred to (for highlighting and scrolling).
    public let taskIDs: [UUID]

    public init(id: UUID = UUID(), kind: ToolKind, parameters: [ToolParameter], outcome: ToolOutcome, taskIDs: [UUID] = []) {
        self.id = id
        self.kind = kind
        self.parameters = parameters
        self.outcome = outcome
        self.taskIDs = taskIDs
    }

    /// Whether the call succeeded.
    public var succeeded: Bool {
        if case .success = outcome { return true }
        return false
    }
}

/// The assistant's tools.
public enum ToolKind: String, Hashable, Sendable, CaseIterable {
    case findTasks, addTask, setPriority, completeTask, deleteTask, switchLayout, setAccentColor, setTaskColor, addStep
}

/// A typed tool parameter, localised by the UI and drawn as a token pill.
public enum ToolParameter: Hashable, Sendable {
    case task(title: String, id: UUID?)
    case query(String)
    case text(String)
    case category(TaskCategory)
    case priority(TaskPriority)
    case layout(BoardLayout)
    case accent(AccentTheme)
    case color(TileColor)
}

/// What happened when a tool ran.
public enum ToolOutcome: Hashable, Sendable {
    /// The change was made (or, for lookups, results were returned).
    case success
    /// The request was valid but nothing needed to change.
    case unchanged
    /// The tool could not act.
    case failure(ToolFailure)
}

/// Why a tool could not act.
public enum ToolFailure: Hashable, Sendable {
    case noMatch(query: String)
    case ambiguous(query: String, candidates: [String])
    case emptyTitle
    case rejected(String)
}
