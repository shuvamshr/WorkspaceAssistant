import Foundation
import WorkspaceDomain

/// A canned engine for SwiftUI previews: replies with one action block and a sentence.
/// (Features can't import `WorkspaceAgent`, so previews don't use `ScriptedEngine` directly.)
@MainActor
final class PreviewAssistantEngine: AssistantEngine {
    var availability: AssistantAvailability { .available }
    let simulationReason: AssistantUnavailableReason?
    var isResponding = false

    init(simulationReason: AssistantUnavailableReason? = .deviceNotEligible) {
        self.simulationReason = simulationReason
    }

    func send(_ prompt: String) -> AsyncThrowingStream<AssistantEvent, any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.toolCalled(ToolActivity(kind: .switchLayout, parameters: [.layout(.focus)], outcome: .success)))
            continuation.yield(.completed("Done — I switched to Focus."))
            continuation.finish()
        }
    }

    func reset() async {}
    func prewarm() async {}
}
