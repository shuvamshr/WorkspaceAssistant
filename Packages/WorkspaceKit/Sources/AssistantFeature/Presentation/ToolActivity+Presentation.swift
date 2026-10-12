import DesignSystem
import Foundation
import WorkspaceDomain

extension ToolKind {
    /// Glyph for the action block.
    var glyph: String {
        switch self {
        case .findTasks: "magnifyingglass"
        case .addTask: "plus"
        case .setPriority: "star.fill"
        case .completeTask: "checkmark"
        case .deleteTask: "trash"
        case .switchLayout: "square.grid.2x2"
        case .setAccentColor, .setTaskColor: "paintpalette"
        case .addStep: "list.bullet"
        }
    }

    /// Colour for the action block's glyph square.
    var color: TileColor {
        switch self {
        case .findTasks: .gray
        case .addTask: .green
        case .setPriority: .orange
        case .completeTask: .mint
        case .deleteTask: .red
        case .switchLayout: .blue
        case .setAccentColor, .setTaskColor: .purple
        case .addStep: .teal
        }
    }
}

extension ToolParameter {
    /// Localised token text.
    var displayText: String {
        switch self {
        case let .task(title, _): title
        case let .query(query): query
        case let .text(text): text
        case let .category(category): category.displayName
        case let .priority(priority): priority == .high ? String(localized: "High", bundle: .module) : String(localized: "Normal", bundle: .module)
        case let .layout(layout): layout.displayName
        case let .accent(theme): theme.displayName
        case let .color(color): color.displayName
        }
    }

    var taskID: UUID? {
        if case let .task(_, id) = self { return id }
        return nil
    }
}

extension ToolActivity {
    private var subject: String { parameters.first?.displayText ?? "" }

    private func parameter(at index: Int) -> String {
        parameters.indices.contains(index) ? parameters[index].displayText : ""
    }

    private var isDeprioritise: Bool { parameters.contains(.priority(.normal)) }

    /// The block's sentence as verb, text and token parts.
    var blockParts: [ActionBlockPart] {
        switch kind {
        case .findTasks: [.verb(String(localized: "Find tasks matching", bundle: .module)), .token(subject)]
        case .addTask: [.verb(String(localized: "Add task", bundle: .module)), .token(subject), .text(String(localized: "in", bundle: .module)), .token(parameter(at: 1))]
        case .setPriority:
            isDeprioritise
                ? [.verb(String(localized: "Remove priority from", bundle: .module)), .token(subject)]
                : [.verb(String(localized: "Prioritise", bundle: .module)), .token(subject)]
        case .completeTask: [.verb(String(localized: "Complete", bundle: .module)), .token(subject)]
        case .deleteTask: [.verb(String(localized: "Delete", bundle: .module)), .token(subject)]
        case .switchLayout: [.verb(String(localized: "Switch layout to", bundle: .module)), .token(subject)]
        case .setAccentColor: [.verb(String(localized: "Set accent colour to", bundle: .module)), .token(subject)]
        case .setTaskColor: [.verb(String(localized: "Colour", bundle: .module)), .token(subject), .text(String(localized: "as", bundle: .module)), .token(parameter(at: 1))]
        case .addStep: [.verb(String(localized: "Add step", bundle: .module)), .token(parameter(at: 1)), .text(String(localized: "to", bundle: .module)), .token(subject)]
        }
    }

    /// Localised reason when the call didn't change anything.
    var failureReason: String? {
        switch outcome {
        case .success: nil
        case .unchanged: String(localized: "Already set — nothing changed.", bundle: .module)
        case let .failure(.noMatch(query)): String(localized: "No task matches “\(query)”.", bundle: .module)
        case let .failure(.ambiguous(query, candidates)):
            String(localized: "“\(query)” matches \(candidates.formatted(.list(type: .and))).", bundle: .module)
        case .failure(.emptyTitle): String(localized: "The title was empty.", bundle: .module)
        case .failure(.rejected): String(localized: "The change couldn’t be made.", bundle: .module)
        }
    }

    /// What VoiceOver reads, e.g. "Assistant prioritised Refactor Network Layer".
    var spokenSentence: String {
        if let reason = failureReason, !succeeded {
            return String(localized: "Assistant couldn’t complete the action. \(reason)", bundle: .module)
        }
        switch kind {
        case .findTasks: return String(localized: "Assistant looked up tasks matching \(subject)", bundle: .module)
        case .addTask: return String(localized: "Assistant added \(subject)", bundle: .module)
        case .setPriority:
            return isDeprioritise
                ? String(localized: "Assistant removed priority from \(subject)", bundle: .module)
                : String(localized: "Assistant prioritised \(subject)", bundle: .module)
        case .completeTask: return String(localized: "Assistant completed \(subject)", bundle: .module)
        case .deleteTask: return String(localized: "Assistant deleted \(subject). You can undo this.", bundle: .module)
        case .switchLayout: return String(localized: "Assistant switched layout to \(subject)", bundle: .module)
        case .setAccentColor: return String(localized: "Assistant set the accent colour to \(subject)", bundle: .module)
        case .setTaskColor: return String(localized: "Assistant coloured \(subject) \(parameter(at: 1))", bundle: .module)
        case .addStep: return String(localized: "Assistant added step \(parameter(at: 1)) to \(subject)", bundle: .module)
        }
    }

    /// The task this block refers to, if exactly one.
    var referencedTaskID: UUID? {
        parameters.lazy.compactMap(\.taskID).first ?? (taskIDs.count == 1 ? taskIDs.first : nil)
    }
}
