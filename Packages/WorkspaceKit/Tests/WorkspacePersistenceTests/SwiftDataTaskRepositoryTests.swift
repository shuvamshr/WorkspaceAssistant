import Foundation
import Testing
@testable import WorkspaceDomain
@testable import WorkspacePersistence

@MainActor
@Suite("SwiftData persistence")
struct SwiftDataTaskRepositoryTests {
    @Test func roundTripsEveryField() throws {
        let repository = try SwiftDataTaskRepository(inMemory: true)
        let task = TaskItem(
            title: "Ship it", notes: "Release notes", category: .operations, priority: .high, status: .done,
            origin: .assistant, appearance: TileAppearance(color: .mint, glyph: "airplane"),
            steps: [TaskStep(title: "Tag build", isDone: true), TaskStep(title: "Upload")],
            createdAt: Date(timeIntervalSince1970: 1_700_000_000), sortIndex: 4.5
        )
        try repository.upsert([task])
        #expect(try repository.fetchAll() == [task])
    }

    @Test func upsertUpdatesExistingRecord() throws {
        let repository = try SwiftDataTaskRepository(inMemory: true)
        var task = TaskItem(title: "Draft", category: .design)
        try repository.upsert([task])
        task.title = "Final"
        task.steps = [TaskStep(title: "Review")]
        try repository.upsert([task])
        let stored = try repository.fetchAll()
        #expect(stored.count == 1)
        #expect(stored.first?.title == "Final")
        #expect(stored.first?.steps.map(\.title) == ["Review"])
    }

    @Test func deleteRemovesOnlyGivenIDs() throws {
        let repository = try SwiftDataTaskRepository(inMemory: true)
        let tasks = SampleData.tasks()
        try repository.upsert(tasks)
        try repository.delete(ids: [tasks[0].id, tasks[2].id])
        #expect(Set(try repository.fetchAll().map(\.id)) == Set(tasks.map(\.id)).subtracting([tasks[0].id, tasks[2].id]))
    }

    @Test func storeSeedsAndPersistsThroughSwiftData() throws {
        let repository = try SwiftDataTaskRepository(inMemory: true)
        let preferences = InMemoryPreferencesStore()
        let store = WorkspaceStore(repository: repository, preferencesStore: preferences)
        #expect(try repository.fetchAll().count == 6)

        try store.perform(.addTask(title: "Code review", category: .development, priority: .high, origin: .user))
        let reloaded = WorkspaceStore(repository: repository, preferencesStore: preferences)
        #expect(reloaded.tasks.first?.title == "Code review")
        #expect(reloaded.tasks.count == 7)
    }

    @Test func userDefaultsPreferencesRoundTrip() throws {
        let suite = "WorkspacePersistenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsPreferencesStore(defaults: defaults)
        #expect(store.load() == WorkspacePreferences())
        #expect(!store.hasSeededSampleTasks)

        let preferences = WorkspacePreferences(layout: .board, accent: .teal, listDensity: .compact)
        store.save(preferences)
        store.hasSeededSampleTasks = true
        let reloaded = UserDefaultsPreferencesStore(defaults: defaults)
        #expect(reloaded.load() == preferences)
        #expect(reloaded.hasSeededSampleTasks)
    }
}
