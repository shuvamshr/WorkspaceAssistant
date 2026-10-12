import Foundation
import SwiftData
import WorkspaceDomain

/// A `TaskRepository` backed by SwiftData.
@MainActor
public final class SwiftDataTaskRepository: TaskRepository {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    /// Creates a repository. Pass `inMemory: true` for tests.
    public init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(for: TaskRecord.self, configurations: configuration)
    }

    public func fetchAll() throws -> [TaskItem] {
        try context.fetch(FetchDescriptor<TaskRecord>(sortBy: [SortDescriptor(\.sortIndex)])).map(\.taskItem)
    }

    public func upsert(_ tasks: [TaskItem]) throws {
        guard !tasks.isEmpty else { return }
        let ids = tasks.map(\.id)
        let existing = try context.fetch(FetchDescriptor<TaskRecord>(predicate: #Predicate { ids.contains($0.id) }))
        let byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for task in tasks {
            if let record = byID[task.id] {
                record.update(from: task)
            } else {
                context.insert(TaskRecord(task: task))
            }
        }
        try context.save()
    }

    public func delete(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        try context.delete(model: TaskRecord.self, where: #Predicate { ids.contains($0.id) })
        try context.save()
    }
}
