import Foundation

/// Navigation value for pushing a task's detail editor.
public struct TaskRoute: Hashable, Sendable {
    public let taskID: UUID

    public init(taskID: UUID) {
        self.taskID = taskID
    }
}
