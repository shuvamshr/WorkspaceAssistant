import Foundation

/// A record of one performed command, for the activity log.
public struct ActivityEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let date: Date
    public let actor: CommandActor
    public let command: WorkspaceCommand
    public let changedTaskIDs: [UUID]

    public init(id: UUID = UUID(), date: Date = .now, actor: CommandActor, command: WorkspaceCommand, changedTaskIDs: [UUID]) {
        self.id = id
        self.date = date
        self.actor = actor
        self.command = command
        self.changedTaskIDs = changedTaskIDs
    }
}
