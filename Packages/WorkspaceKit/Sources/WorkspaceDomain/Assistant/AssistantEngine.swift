/// An assistant that turns natural-language prompts into workspace commands via tools.
///
/// Implemented by `FoundationModelsEngine` (Apple Intelligence) and `ScriptedEngine` (simulated stand-in).
@MainActor
public protocol AssistantEngine: AnyObject, Sendable {
    /// Whether this engine can respond right now.
    var availability: AssistantAvailability { get }
    /// Non-nil when this is the simulated stand-in, explaining why the real model isn't used.
    var simulationReason: AssistantUnavailableReason? { get }
    /// Whether a response is in flight.
    var isResponding: Bool { get }
    /// Sends a prompt. The stream yields tool calls and text, then finishes or throws `AssistantError`.
    /// Cancelling the consuming task cancels generation.
    func send(_ prompt: String) -> AsyncThrowingStream<AssistantEvent, any Error>
    /// Forgets the conversation and starts a fresh session.
    func reset() async
    /// Loads resources ahead of the first prompt.
    func prewarm() async
}
