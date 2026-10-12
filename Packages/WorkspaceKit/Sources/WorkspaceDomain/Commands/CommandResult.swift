import Foundation

/// The factual outcome of performing a command.
public struct CommandResult: Hashable, Sendable {
    /// Tasks the command targeted (whether or not their values changed).
    public var affectedTaskIDs: [UUID]
    /// Tasks whose stored values actually changed.
    public var changedTaskIDs: [UUID]
    /// The task created by `addTask` or `duplicateTask`, if any.
    public var createdTaskID: UUID?
    /// The step created by `addStep`, if any.
    public var createdStepID: UUID?

    public init(
        affectedTaskIDs: [UUID] = [],
        changedTaskIDs: [UUID] = [],
        createdTaskID: UUID? = nil,
        createdStepID: UUID? = nil
    ) {
        self.affectedTaskIDs = affectedTaskIDs
        self.changedTaskIDs = changedTaskIDs
        self.createdTaskID = createdTaskID
        self.createdStepID = createdStepID
    }

    /// Whether anything actually changed.
    public var didChange: Bool { !changedTaskIDs.isEmpty }
}
