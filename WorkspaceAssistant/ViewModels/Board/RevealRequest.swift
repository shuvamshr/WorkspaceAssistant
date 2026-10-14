import Foundation

/// Asks the visible board to scroll a task into view. A fresh `token` re-triggers the same task.
public struct RevealRequest: Hashable, Sendable {
    public let taskID: UUID
    public let token = UUID()

    public init(taskID: UUID) {
        self.taskID = taskID
    }
}
