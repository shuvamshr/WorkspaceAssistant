import Foundation

/// A `TaskRepository` that keeps tasks in memory. For previews and tests.
@MainActor
public final class InMemoryTaskRepository: TaskRepository {
    private var storage: [UUID: TaskItem]

    public init(tasks: [TaskItem] = []) {
        storage = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
    }

    public func fetchAll() throws -> [TaskItem] { Array(storage.values) }

    public func upsert(_ tasks: [TaskItem]) throws {
        for task in tasks { storage[task.id] = task }
    }

    public func delete(ids: [UUID]) throws {
        for id in ids { storage[id] = nil }
    }
}
