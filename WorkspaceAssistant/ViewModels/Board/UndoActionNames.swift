import Foundation

/// Localised undo menu names for commands ("Undo Prioritise").
public enum UndoActionNames {
    /// The action name for a command, or `nil` for none.
    public static func name(for command: WorkspaceCommand) -> String? {
        switch command {
        case .addTask, .insertTasks: String(localized: "Add Task")
        case .updateTask: String(localized: "Edit Task")
        case let .setPriority(_, priority):
            priority == .high ? String(localized: "Prioritise") : String(localized: "Remove Priority")
        case let .setStatus(_, status):
            status == .done ? String(localized: "Complete") : String(localized: "Reopen")
        case .deleteTasks: String(localized: "Delete")
        case .moveTask: String(localized: "Move")
        case .setAppearance: String(localized: "Change Appearance")
        case .duplicateTask: String(localized: "Duplicate")
        case .addStep: String(localized: "Add Step")
        case .toggleStep: String(localized: "Check Step")
        case .renameStep: String(localized: "Rename Step")
        case .deleteStep: String(localized: "Delete Step")
        case .moveSteps: String(localized: "Move Step")
        case .replaceTasks: nil
        case .setLayout: String(localized: "Change Layout")
        case .setAccent: String(localized: "Change Accent Colour")
        case .setListDensity: String(localized: "Change Density")
        }
    }
}
