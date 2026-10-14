import Foundation
import Observation
import os

/// State for the assistant panel: the transcript, the draft, and the response lifecycle.
@MainActor
@Observable
public final class AssistantViewModel {
    /// Transcript entries, oldest first.
    public private(set) var items: [TranscriptItem] = []
    /// Text in the composer.
    public var draft = ""
    /// Whether a response is in flight.
    public private(set) var phase: AssistantPhase = .idle
    /// Whether the engine can respond, refreshed on `refreshAvailability()`.
    public private(set) var availability: AssistantAvailability
    /// Non-nil when the simulated assistant is in use.
    public private(set) var simulationReason: AssistantUnavailableReason?
    /// Changes when something asks for the composer to take focus (⌘K).
    public private(set) var focusRequest = 0
    /// The most recent tool activity, for announcements.
    public private(set) var lastActivity: ToolActivity?

    @ObservationIgnored private let engine: any AssistantEngine
    @ObservationIgnored private var responseTask: Task<Void, Never>?
    @ObservationIgnored private let now: () -> Date

    public init(engine: any AssistantEngine, now: @escaping () -> Date = { .now }) {
        self.engine = engine
        self.now = now
        availability = engine.availability
        simulationReason = engine.simulationReason
    }

    /// Whether the transcript has anything in it.
    public var hasConversation: Bool { !items.isEmpty }

    /// Re-reads availability (e.g. when the app returns to the foreground).
    public func refreshAvailability() {
        availability = engine.availability
        simulationReason = engine.simulationReason
    }

    /// Prepares the engine ahead of the first prompt.
    public func prewarm() async {
        await engine.prewarm()
    }

    /// Asks the composer to take keyboard focus.
    public func requestFocus() {
        focusRequest += 1
    }

    /// Sends a suggested prompt.
    public func send(suggestion: AssistantSuggestion) {
        draft = suggestion.prompt
        send()
    }

    /// Sends the draft. Ignored while responding or when the draft is blank.
    public func send() {
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, phase == .idle else { return }
        draft = ""
        items.append(TranscriptItem(date: now(), content: .user(prompt)))
        phase = .responding
        refreshAvailability()

        let stream = engine.send(prompt)
        responseTask = Task { [weak self] in
            do {
                for try await event in stream {
                    guard let self, !Task.isCancelled else { break }
                    self.handle(event)
                }
                self?.finish(cancelled: Task.isCancelled)
            } catch {
                self?.fail(error)
            }
        }
    }

    /// Stops the current response.
    public func cancel() {
        guard phase == .responding else { return }
        responseTask?.cancel()
        responseTask = nil
        finish(cancelled: true)
    }

    /// Clears the conversation and resets the engine's session. Never touches tasks or layout.
    public func clear() {
        cancel()
        items.removeAll()
        lastActivity = nil
        Task { await engine.reset() }
    }

    // MARK: - Events

    private func handle(_ event: AssistantEvent) {
        switch event {
        case let .toolCalled(activity):
            lastActivity = activity
            let item = TranscriptItem(date: now(), content: .action(activity))
            if let index = streamingIndex {
                items.insert(item, at: index)
            } else {
                items.append(item)
            }
        case let .partialText(text):
            updateReply(text, isStreaming: true)
        case let .completed(text):
            updateReply(text, isStreaming: false)
        }
    }

    private var streamingIndex: Int? {
        items.lastIndex { item in
            if case .assistant(_, true) = item.content { return true }
            return false
        }
    }

    private func updateReply(_ text: String, isStreaming: Bool) {
        if let index = streamingIndex {
            items[index].content = .assistant(text, isStreaming: isStreaming)
        } else if !text.isEmpty {
            items.append(TranscriptItem(date: now(), content: .assistant(text, isStreaming: isStreaming)))
        }
    }

    private func finish(cancelled: Bool) {
        guard phase == .responding else { return }
        if let index = streamingIndex {
            if case let .assistant(text, _) = items[index].content, text.isEmpty {
                items.remove(at: index)
            } else if case let .assistant(text, _) = items[index].content {
                items[index].content = .assistant(text, isStreaming: false)
            }
        }
        if cancelled { items.append(TranscriptItem(date: now(), content: .notice(.stopped))) }
        phase = .idle
        responseTask = nil
    }

    private func fail(_ error: any Error) {
        if error is CancellationError {
            finish(cancelled: true)
            return
        }
        let mapped = error as? AssistantError ?? .other(String(describing: error))
        Log.agent.error("Assistant response failed: \(String(describing: mapped), privacy: .public)")
        finish(cancelled: false)
        items.append(TranscriptItem(date: now(), content: .notice(.error(mapped))))
    }
}
