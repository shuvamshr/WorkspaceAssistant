import WorkspaceDomain

/// Uses Apple Intelligence when it's available and the scripted stand-in otherwise,
/// re-checking availability on every prompt (e.g. once the model finishes downloading).
@MainActor
public final class AutomaticAssistantEngine: AssistantEngine {
    private let primary: FoundationModelsEngine
    private let executor: any WorkspaceCommandExecutor
    private var fallback: ScriptedEngine?

    public init(executor: any WorkspaceCommandExecutor) {
        self.executor = executor
        primary = FoundationModelsEngine(executor: executor)
    }

    private var active: any AssistantEngine {
        if case let .unavailable(reason) = primary.availability {
            if let fallback, fallback.simulationReason == reason { return fallback }
            let engine = ScriptedEngine(executor: executor, reason: reason)
            fallback = engine
            return engine
        }
        return primary
    }

    public var availability: AssistantAvailability { active.availability }
    public var simulationReason: AssistantUnavailableReason? { active.simulationReason }
    public var isResponding: Bool { primary.isResponding || (fallback?.isResponding ?? false) }

    public func send(_ prompt: String) -> AsyncThrowingStream<AssistantEvent, any Error> {
        active.send(prompt)
    }

    public func reset() async {
        await primary.reset()
        await fallback?.reset()
    }

    public func prewarm() async {
        await active.prewarm()
    }
}
