import Foundation
import WorkspaceDomain

extension TaskItem {
    /// VoiceOver label, e.g. "Refactor Network Layer, Development, high priority, added by assistant".
    public var accessibilitySummary: String {
        var parts = [title, category.displayName]
        if isHighPriority { parts.append(String(localized: "high priority", bundle: .module)) }
        if isDone { parts.append(String(localized: "completed", bundle: .module)) }
        if !steps.isEmpty {
            parts.append(String(localized: "\(completedStepCount) of \(steps.count) steps done", bundle: .module))
        }
        if origin == .assistant { parts.append(String(localized: "added by assistant", bundle: .module)) }
        return parts.joined(separator: ", ")
    }

    /// Short secondary line for tiles: category, or step progress when the task has steps.
    public var tileCaption: String {
        steps.isEmpty
            ? category.displayName
            : String(localized: "\(completedStepCount)/\(steps.count) steps", bundle: .module)
    }
}
