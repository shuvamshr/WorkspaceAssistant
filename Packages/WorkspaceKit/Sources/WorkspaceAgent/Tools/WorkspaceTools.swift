import FoundationModels
import WorkspaceDomain

/// Builds the assistant's tool set over a toolbox and recorder.
enum WorkspaceTools {
    static func make(toolbox: WorkspaceToolbox, recorder: ToolActivityRecorder) -> [any Tool] {
        [
            FindTasksTool(toolbox: toolbox, recorder: recorder),
            AddTaskTool(toolbox: toolbox, recorder: recorder),
            SetTaskPriorityTool(toolbox: toolbox, recorder: recorder),
            CompleteTaskTool(toolbox: toolbox, recorder: recorder),
            DeleteTaskTool(toolbox: toolbox, recorder: recorder),
            SwitchLayoutTool(toolbox: toolbox, recorder: recorder),
            SetAccentColorTool(toolbox: toolbox, recorder: recorder),
            SetTaskColorTool(toolbox: toolbox, recorder: recorder),
            AddStepTool(toolbox: toolbox, recorder: recorder),
        ]
    }
}

/// Runs a toolbox operation on the main actor, reports its activity, and returns the message.
private func run(_ recorder: ToolActivityRecorder, _ operation: @MainActor () -> ToolResult) async -> String {
    await MainActor.run {
        let result = operation()
        recorder.record(result.activity)
        return result.message
    }
}

/// Looks up tasks by title words before acting.
struct FindTasksTool: Tool {
    let name = "findTasks"
    let description = "Looks up tasks by title. Returns titles, ids, category, priority and status. Use an empty query to list all open tasks."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        @Guide(description: "Words from the task title, or empty to list all open tasks")
        var query: String
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) { toolbox.findTasks(query: arguments.query) }
    }
}

/// Creates a task.
struct AddTaskTool: Tool {
    let name = "addTask"
    let description = "Creates a new task."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        @Guide(description: "Short task title in title case, e.g. 'Code Review'")
        var title: String
        var category: CategoryArgument
        var priority: PriorityArgument
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) {
            toolbox.addTask(title: arguments.title, category: arguments.category.domain, priority: arguments.priority.domain)
        }
    }
}

/// Prioritises or deprioritises a task.
struct SetTaskPriorityTool: Tool {
    let name = "setTaskPriority"
    let description = "Sets a task's priority to high (prioritise) or normal (deprioritise)."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        @Guide(description: "The task's title or words from it, or its id")
        var query: String
        var priority: PriorityArgument
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) { toolbox.setTaskPriority(query: arguments.query, priority: arguments.priority.domain) }
    }
}

/// Marks a task as done.
struct CompleteTaskTool: Tool {
    let name = "completeTask"
    let description = "Marks a task as done."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        @Guide(description: "The task's title or words from it, or its id")
        var query: String
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) { toolbox.completeTask(query: arguments.query) }
    }
}

/// Deletes a task (undoable by the user).
struct DeleteTaskTool: Tool {
    let name = "deleteTask"
    let description = "Deletes a task. Only use when the user explicitly asks to delete or remove it."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        @Guide(description: "The task's title or words from it, or its id")
        var query: String
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) { toolbox.deleteTask(query: arguments.query) }
    }
}

/// Changes how the board presents tasks.
struct SwitchLayoutTool: Tool {
    let name = "switchLayout"
    let description = "Switches the board layout: grid (tiles), list (rows), focus (priority first) or board (columns)."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        var layout: LayoutArgument
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) { toolbox.switchLayout(arguments.layout.domain) }
    }
}

/// Changes the app's accent colour.
struct SetAccentColorTool: Tool {
    let name = "setAccentColor"
    let description = "Changes the app's accent colour."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        var theme: AccentArgument
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) { toolbox.setAccentColor(arguments.theme.domain) }
    }
}

/// Changes one task tile's colour.
struct SetTaskColorTool: Tool {
    let name = "setTaskColor"
    let description = "Changes the colour of one task's tile."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        @Guide(description: "The task's title or words from it, or its id")
        var query: String
        var color: TileColorArgument
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) { toolbox.setTaskColor(query: arguments.query, color: arguments.color.domain) }
    }
}

/// Adds a checklist step to a task.
struct AddStepTool: Tool {
    let name = "addStep"
    let description = "Adds a checklist step to a task."
    let toolbox: WorkspaceToolbox
    let recorder: ToolActivityRecorder

    @Generable
    struct Arguments {
        @Guide(description: "The task's title or words from it, or its id")
        var query: String
        @Guide(description: "The step to add, e.g. 'Write release notes'")
        var stepTitle: String
    }

    func call(arguments: Arguments) async throws -> String {
        await run(recorder) { toolbox.addStep(query: arguments.query, stepTitle: arguments.stepTitle) }
    }
}
