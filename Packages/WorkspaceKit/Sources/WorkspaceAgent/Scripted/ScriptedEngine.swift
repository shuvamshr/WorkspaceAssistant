import Foundation
import WorkspaceDomain

/// A deterministic stand-in for the language model, used when Apple Intelligence isn't available,
/// in previews and in UI tests. It runs the same toolbox code paths as the real tools.
/// The UI must always label it as a simulated assistant.
@MainActor
public final class ScriptedEngine: AssistantEngine {
    private let toolbox: WorkspaceToolbox
    private let executor: any WorkspaceCommandExecutor
    private let reason: AssistantUnavailableReason
    private let wordDelay: Duration
    public private(set) var isResponding = false

    /// - Parameters:
    ///   - reason: Why the simulated assistant is in use (shown in the UI).
    ///   - wordDelay: Delay between streamed words; use `.zero` in tests.
    public init(executor: any WorkspaceCommandExecutor, reason: AssistantUnavailableReason, wordDelay: Duration = .milliseconds(25)) {
        self.executor = executor
        toolbox = WorkspaceToolbox(executor: executor)
        self.reason = reason
        self.wordDelay = wordDelay
    }

    public var availability: AssistantAvailability { .available }
    public var simulationReason: AssistantUnavailableReason? { reason }

    public func send(_ prompt: String) -> AsyncThrowingStream<AssistantEvent, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                await self.respond(to: prompt, continuation: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func reset() async {}
    public func prewarm() async {}

    private func respond(to prompt: String, continuation: AsyncThrowingStream<AssistantEvent, any Error>.Continuation) async {
        guard !isResponding else {
            continuation.finish(throwing: AssistantError.busy)
            return
        }
        isResponding = true
        defer { isResponding = false }

        let results = ScriptedIntentParser.parse(prompt).flatMap(run)
        for result in results {
            continuation.yield(.toolCalled(result.activity))
        }
        let reply = Self.reply(for: results)
        do {
            var streamed = ""
            for word in reply.split(separator: " ", omittingEmptySubsequences: false) {
                try Task.checkCancellation()
                streamed += streamed.isEmpty ? String(word) : " " + word
                continuation.yield(.partialText(streamed))
                if wordDelay > .zero { try await Task.sleep(for: wordDelay) }
            }
            continuation.yield(.completed(reply))
            continuation.finish()
        } catch {
            continuation.finish(throwing: CancellationError())
        }
    }

    private func run(_ intent: ScriptedIntent) -> [ToolResult] {
        switch intent {
        case let .setPriority(query, priority): [toolbox.setTaskPriority(query: query, priority: priority)]
        case let .setCategoryPriority(category, priority):
            executor.tasks
                .filter { $0.category == category && !$0.isDone }
                .map { toolbox.setTaskPriority(query: $0.id.uuidString, priority: priority) }
        case let .complete(query): [toolbox.completeTask(query: query)]
        case let .delete(query): [toolbox.deleteTask(query: query)]
        case let .addTask(title, category, priority): [toolbox.addTask(title: title, category: category, priority: priority)]
        case let .addStep(query, step): [toolbox.addStep(query: query, stepTitle: step)]
        case let .switchLayout(layout): [toolbox.switchLayout(layout)]
        case let .setAccent(theme): [toolbox.setAccentColor(theme)]
        case let .setTaskColor(query, color): [toolbox.setTaskColor(query: query, color: color)]
        case let .find(query): [toolbox.findTasks(query: query)]
        }
    }

    /// Builds a short, truthful reply from what the tools reported.
    static func reply(for results: [ToolResult]) -> String {
        guard !results.isEmpty else {
            return "I'm a simulated assistant, so I only understand simple requests like “Prioritise the network refactor”, “Switch to Board view” or “Add a task for code review”."
        }
        let done = results.filter { $0.activity.succeeded }.map(\.activity)
        let failures = results.filter { !$0.activity.succeeded }.map(\.activity)
        var sentences: [String] = []
        if !done.isEmpty {
            sentences.append("Done — I " + ListFormatter.localizedString(byJoining: done.map(phrase)) + ".")
        }
        for failure in failures {
            sentences.append(sentence(for: failure))
        }
        return sentences.joined(separator: " ")
    }

    private static func phrase(_ activity: ToolActivity) -> String {
        let task = activity.parameters.lazy.compactMap { if case let .task(title, _) = $0 { "“\(title)”" } else { nil } }.first ?? "it"
        switch activity.kind {
        case .findTasks: return "found \(activity.taskIDs.count) matching task(s)"
        case .addTask: return "added \(task)"
        case .setPriority:
            return activity.parameters.contains(.priority(.normal)) ? "removed priority from \(task)" : "prioritised \(task)"
        case .completeTask: return "completed \(task)"
        case .deleteTask: return "deleted \(task) (you can undo this)"
        case .switchLayout:
            let layout = activity.parameters.lazy.compactMap { if case let .layout(layout) = $0 { layout.rawValue.capitalized } else { nil } }.first ?? ""
            return "switched to \(layout)"
        case .setAccentColor:
            let theme = activity.parameters.lazy.compactMap { if case let .accent(theme) = $0 { theme.rawValue } else { nil } }.first ?? ""
            return "changed the accent colour to \(theme)"
        case .setTaskColor: return "recoloured \(task)"
        case .addStep: return "added a step to \(task)"
        }
    }

    private static func sentence(for activity: ToolActivity) -> String {
        switch activity.outcome {
        case .success: return ""
        case .unchanged:
            let task = activity.parameters.lazy.compactMap { if case let .task(title, _) = $0 { "“\(title)”" } else { nil } }.first
            return task.map { "\($0) didn't need changing." } ?? "That was already set."
        case let .failure(.noMatch(query)): return "I couldn't find a task matching “\(query)”."
        case let .failure(.ambiguous(query, candidates)):
            return "“\(query)” matches \(ListFormatter.localizedString(byJoining: candidates.map { "“\($0)”" })) — which one did you mean?"
        case .failure(.emptyTitle): return "I need a title for that."
        case .failure(.rejected): return "Something went wrong, so nothing was changed."
        }
    }
}
