import Foundation

/// The most recent change made by the assistant. A fresh `id` per change lets views animate.
public struct AssistantChange: Hashable, Sendable {
    public let id: UUID
    public let taskIDs: [UUID]

    public init(id: UUID = UUID(), taskIDs: [UUID]) {
        self.id = id
        self.taskIDs = taskIDs
    }
}
