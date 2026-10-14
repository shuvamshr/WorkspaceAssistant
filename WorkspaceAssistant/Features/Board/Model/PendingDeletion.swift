import Foundation

/// A deletion waiting for confirmation.
public struct PendingDeletion: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let taskIDs: [UUID]

    public init(taskIDs: [UUID]) {
        self.taskIDs = taskIDs
    }
}
