import Foundation

extension TaskItem {
    /// VoiceOver label, e.g. "Refactor Network Layer, Development, high priority, added by assistant".
    public var accessibilitySummary: String {
        var parts = [title, category.displayName]
        if isHighPriority { parts.append(String(localized: "high priority")) }
        if isDone { parts.append(String(localized: "completed")) }
        if !steps.isEmpty {
            parts.append(String(localized: "\(completedStepCount) of \(steps.count) steps done"))
        }
        if origin == .assistant { parts.append(String(localized: "added by assistant")) }
        return parts.joined(separator: ", ")
    }

    /// Short secondary line for tiles: category, or step progress when the task has steps.
    public var tileCaption: String {
        steps.isEmpty
            ? category.displayName
            : String(localized: "\(completedStepCount)/\(steps.count) steps")
    }
}
