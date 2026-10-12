import Foundation
import WorkspaceDomain

/// Localised undo menu names for commands ("Undo Prioritise").
public enum UndoActionNames {
    /// The action name for a command, or `nil` for none.
    public static func name(for command: WorkspaceCommand) -> String? {
        switch command {
        case .addTask, .insertTasks: String(localized: "Add Task", bundle: .module)
        case .updateTask: String(localized: "Edit Task", bundle: .module)
        case let .setPriority(_, priority):
            priority == .high ? String(localized: "Prioritise", bundle: .module) : String(localized: "Remove Priority", bundle: .module)
        case let .setStatus(_, status):
            status == .done ? String(localized: "Complete", bundle: .module) : String(localized: "Reopen", bundle: .module)
        case .deleteTasks: String(localized: "Delete", bundle: .module)
        case .moveTask: String(localized: "Move", bundle: .module)
        case .setAppearance: String(localized: "Change Appearance", bundle: .module)
        case .duplicateTask: String(localized: "Duplicate", bundle: .module)
        case .addStep: String(localized: "Add Step", bundle: .module)
        case .toggleStep: String(localized: "Check Step", bundle: .module)
        case .renameStep: String(localized: "Rename Step", bundle: .module)
        case .deleteStep: String(localized: "Delete Step", bundle: .module)
        case .moveSteps: String(localized: "Move Step", bundle: .module)
        case .replaceTasks: nil
        case .setLayout: String(localized: "Change Layout", bundle: .module)
        case .setAccent: String(localized: "Change Accent Colour", bundle: .module)
        case .setListDensity: String(localized: "Change Density", bundle: .module)
        }
    }
}
