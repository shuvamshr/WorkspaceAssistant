import Foundation
import os

/// The tools' shared logic: resolve tasks, issue `WorkspaceCommand`s as `.assistant`, and report
/// truthfully what happened — including "no match", "ambiguous" and "already done".
///
/// Used by the Foundation Models tool adapters and by `ScriptedEngine`, so both paths behave identically.
@MainActor
public final class WorkspaceToolbox: Sendable {
    private let executor: any WorkspaceCommandExecutor

    public init(executor: any WorkspaceCommandExecutor) {
        self.executor = executor
    }

    // MARK: - Lookup

    /// Lists tasks matching `query` (or all open tasks for an empty query) with ids and state.
    public func findTasks(query: String) -> ToolResult {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches: [TaskItem]
        if trimmed.isEmpty {
            matches = executor.tasks.filter { !$0.isDone }
        } else {
            switch executor.resolveTasks(matching: trimmed) {
            case .none: matches = []
            case let .unique(task): matches = [task]
            case let .ambiguous(tasks): matches = tasks
            }
        }
        guard !matches.isEmpty else {
            return ToolResult(
                message: "No task matches '\(trimmed)'. \(openTasksSummary())",
                activity: ToolActivity(kind: .findTasks, parameters: [.query(trimmed)], outcome: .failure(.noMatch(query: trimmed)))
            )
        }
        let lines = matches.map { task in
            "- '\(task.title)' (id: \(task.id.uuidString), category: \(task.category.rawValue), priority: \(task.priority.rawValue), status: \(task.status.rawValue), steps: \(task.completedStepCount)/\(task.steps.count))"
        }
        return ToolResult(
            message: "Found \(matches.count) task(s):\n" + lines.joined(separator: "\n"),
            activity: ToolActivity(kind: .findTasks, parameters: [.query(trimmed)], outcome: .success, taskIDs: matches.map(\.id))
        )
    }

    // MARK: - Mutations

    /// Creates a task.
    public func addTask(title: String, category: TaskCategory, priority: TaskPriority) -> ToolResult {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let parameters: [ToolParameter] = [.text(trimmed), .category(category), .priority(priority)]
        do {
            let result = try executor.perform(.addTask(title: trimmed, category: category, priority: priority, origin: .assistant), actor: .assistant)
            let id = result.createdTaskID
            let priorityText = priority == .high ? "high" : "normal"
            return ToolResult(
                message: "Added '\(trimmed)' to \(category.rawValue) with \(priorityText) priority.",
                activity: ToolActivity(kind: .addTask, parameters: [.task(title: trimmed, id: id), .category(category), .priority(priority)], outcome: .success, taskIDs: id.map { [$0] } ?? [])
            )
        } catch WorkspaceError.emptyTitle {
            return ToolResult(
                message: "Not added: the title was empty. Ask the user what the task should be called.",
                activity: ToolActivity(kind: .addTask, parameters: parameters, outcome: .failure(.emptyTitle))
            )
        } catch {
            return failure(.addTask, parameters, error)
        }
    }

    /// Sets a task's priority (covers prioritise and deprioritise).
    public func setTaskPriority(query: String, priority: TaskPriority) -> ToolResult {
        withUniqueTask(query, kind: .setPriority, extra: [.priority(priority)]) { task in
            guard task.priority != priority else {
                return ("'\(task.title)' is already \(priority.rawValue) priority. No change made.", .unchanged)
            }
            try executor.perform(.setPriority(ids: [task.id], priority), actor: .assistant)
            return ("Marked '\(task.title)' as \(priority.rawValue) priority.", .success)
        }
    }

    /// Marks a task as done.
    public func completeTask(query: String) -> ToolResult {
        withUniqueTask(query, kind: .completeTask) { task in
            guard !task.isDone else { return ("'\(task.title)' is already done. No change made.", .unchanged) }
            try executor.perform(.setStatus(ids: [task.id], .done), actor: .assistant)
            return ("Marked '\(task.title)' as done.", .success)
        }
    }

    /// Deletes a task. The user can undo it.
    public func deleteTask(query: String) -> ToolResult {
        withUniqueTask(query, kind: .deleteTask) { task in
            try executor.perform(.deleteTasks(ids: [task.id]), actor: .assistant)
            return ("Deleted '\(task.title)'. The user can undo this from the board.", .success)
        }
    }

    /// Switches the board layout.
    public func switchLayout(_ layout: BoardLayout) -> ToolResult {
        let parameters: [ToolParameter] = [.layout(layout)]
        guard executor.preferences.layout != layout else {
            return ToolResult(
                message: "The board is already in \(layout.rawValue) layout. No change made.",
                activity: ToolActivity(kind: .switchLayout, parameters: parameters, outcome: .unchanged)
            )
        }
        do {
            try executor.perform(.setLayout(layout), actor: .assistant)
            return ToolResult(
                message: "Switched the board to \(layout.rawValue) layout.",
                activity: ToolActivity(kind: .switchLayout, parameters: parameters, outcome: .success)
            )
        } catch {
            return failure(.switchLayout, parameters, error)
        }
    }

    /// Changes the app's accent colour.
    public func setAccentColor(_ theme: AccentTheme) -> ToolResult {
        let parameters: [ToolParameter] = [.accent(theme)]
        guard executor.preferences.accent != theme else {
            return ToolResult(
                message: "The accent colour is already \(theme.rawValue). No change made.",
                activity: ToolActivity(kind: .setAccentColor, parameters: parameters, outcome: .unchanged)
            )
        }
        do {
            try executor.perform(.setAccent(theme), actor: .assistant)
            return ToolResult(
                message: "Changed the accent colour to \(theme.rawValue).",
                activity: ToolActivity(kind: .setAccentColor, parameters: parameters, outcome: .success)
            )
        } catch {
            return failure(.setAccentColor, parameters, error)
        }
    }

    /// Changes a task tile's colour, keeping its glyph.
    public func setTaskColor(query: String, color: TileColor) -> ToolResult {
        withUniqueTask(query, kind: .setTaskColor, extra: [.color(color)]) { task in
            let current = task.resolvedAppearance
            guard current.color != color else {
                return ("'\(task.title)' is already \(color.rawValue). No change made.", .unchanged)
            }
            try executor.perform(.setAppearance(id: task.id, TileAppearance(color: color, glyph: current.glyph)), actor: .assistant)
            return ("Changed '\(task.title)' to \(color.rawValue).", .success)
        }
    }

    /// Adds a checklist step to a task.
    public func addStep(query: String, stepTitle: String) -> ToolResult {
        let step = stepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return withUniqueTask(query, kind: .addStep, extra: [.text(step)]) { task in
            guard !step.isEmpty else { throw WorkspaceError.emptyTitle }
            try executor.perform(.addStep(taskID: task.id, title: step), actor: .assistant)
            return ("Added step '\(step)' to '\(task.title)'.", .success)
        }
    }

    // MARK: - Helpers

    /// Resolves `query` to exactly one task, then runs `body`. Reports none/ambiguous truthfully.
    private func withUniqueTask(
        _ query: String,
        kind: ToolKind,
        extra: [ToolParameter] = [],
        body: (TaskItem) throws -> (String, ToolOutcome)
    ) -> ToolResult {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        switch executor.resolveTasks(matching: trimmed) {
        case .none:
            return ToolResult(
                message: "No task matches '\(trimmed)'. Nothing was changed. \(openTasksSummary())",
                activity: ToolActivity(kind: kind, parameters: [.query(trimmed)] + extra, outcome: .failure(.noMatch(query: trimmed)))
            )
        case let .ambiguous(tasks):
            let titles = tasks.map(\.title)
            let list = titles.map { "'\($0)'" }.joined(separator: ", ")
            return ToolResult(
                message: "Ambiguous: '\(trimmed)' matches \(list). Nothing was changed. Ask the user which one they mean.",
                activity: ToolActivity(kind: kind, parameters: [.query(trimmed)] + extra, outcome: .failure(.ambiguous(query: trimmed, candidates: titles)), taskIDs: tasks.map(\.id))
            )
        case let .unique(task):
            let parameters = [ToolParameter.task(title: task.title, id: task.id)] + extra
            do {
                let (message, outcome) = try body(task)
                return ToolResult(message: message, activity: ToolActivity(kind: kind, parameters: parameters, outcome: outcome, taskIDs: [task.id]))
            } catch WorkspaceError.emptyTitle {
                return ToolResult(
                    message: "Nothing was changed: the text was empty.",
                    activity: ToolActivity(kind: kind, parameters: parameters, outcome: .failure(.emptyTitle), taskIDs: [task.id])
                )
            } catch {
                return failure(kind, parameters, error)
            }
        }
    }

    private func failure(_ kind: ToolKind, _ parameters: [ToolParameter], _ error: any Error) -> ToolResult {
        Log.agent.error("Tool \(kind.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)")
        return ToolResult(
            message: "The change failed and nothing was modified (\(String(describing: error))).",
            activity: ToolActivity(kind: kind, parameters: parameters, outcome: .failure(.rejected(String(describing: error))))
        )
    }

    private func openTasksSummary() -> String {
        let open = executor.tasks.filter { !$0.isDone }.map { "'\($0.title)'" }
        return open.isEmpty ? "There are no open tasks." : "Open tasks: \(open.joined(separator: ", "))."
    }
}
