import CoreTransferable
import Foundation

/// Drag payload carrying a task id, for reordering and moving between Board columns.
public struct TaskDragItem: Transferable, Hashable, Sendable {
    public let id: UUID

    public init(id: UUID) {
        self.id = id
    }

    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: { $0.id.uuidString }, importing: { string in
            guard let id = UUID(uuidString: string) else { throw CocoaError(.coderInvalidValue) }
            return TaskDragItem(id: id)
        })
    }
}
