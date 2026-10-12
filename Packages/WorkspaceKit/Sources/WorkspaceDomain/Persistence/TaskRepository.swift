import Foundation

/// Durable storage for tasks. Implemented with SwiftData in `WorkspacePersistence`
/// and in memory for previews and tests.
@MainActor
public protocol TaskRepository: AnyObject {
    /// Loads every stored task (any order).
    func fetchAll() throws -> [TaskItem]
    /// Inserts or updates the given tasks by id.
    func upsert(_ tasks: [TaskItem]) throws
    /// Deletes tasks with the given ids. Unknown ids are ignored.
    func delete(ids: [UUID]) throws
}
