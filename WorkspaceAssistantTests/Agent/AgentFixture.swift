import Foundation
@testable import WorkspaceAssistant

/// A store over in-memory storage with the six sample tasks.
@MainActor
func makeStore(extra: [TaskItem] = []) -> WorkspaceStore {
    WorkspaceStore(
        repository: InMemoryTaskRepository(),
        preferencesStore: InMemoryPreferencesStore(),
        seed: SampleData.tasks() + extra
    )
}

@MainActor
extension WorkspaceStore {
    func task(titled title: String) -> TaskItem? { tasks.first { $0.title == title } }
}

/// Collects every event from an engine response.
@MainActor
func collect(_ stream: AsyncThrowingStream<AssistantEvent, any Error>) async throws -> [AssistantEvent] {
    var events: [AssistantEvent] = []
    for try await event in stream { events.append(event) }
    return events
}

extension [AssistantEvent] {
    var activities: [ToolActivity] { compactMap { if case let .toolCalled(activity) = $0 { activity } else { nil } } }
    var finalText: String? { compactMap { if case let .completed(text) = $0 { text } else { nil } }.last }
}
