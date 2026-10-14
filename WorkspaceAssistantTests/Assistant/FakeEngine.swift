import Foundation
@testable import WorkspaceAssistant

/// A controllable engine: tests push events and finish the stream manually.
@MainActor
final class FakeEngine: AssistantEngine {
    var availability: AssistantAvailability = .available
    var simulationReason: AssistantUnavailableReason?
    var isResponding = false
    private(set) var prompts: [String] = []
    private(set) var resetCount = 0
    private var continuation: AsyncThrowingStream<AssistantEvent, any Error>.Continuation?
    private(set) var wasTerminated = false

    func send(_ prompt: String) -> AsyncThrowingStream<AssistantEvent, any Error> {
        prompts.append(prompt)
        isResponding = true
        return AsyncThrowingStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { _ in
                Task { @MainActor in self.wasTerminated = true }
            }
        }
    }

    func emit(_ event: AssistantEvent) { continuation?.yield(event) }

    func finish(throwing error: (any Error)? = nil) {
        isResponding = false
        continuation?.finish(throwing: error)
        continuation = nil
    }

    func reset() async { resetCount += 1 }
    func prewarm() async {}
}

/// Lets queued main-actor tasks run.
@MainActor
func settle() async {
    for _ in 0..<5 { await Task.yield() }
    try? await Task.sleep(for: .milliseconds(20))
}
