import DesignSystem
import Foundation
import WorkspaceDomain

extension TaskItem {
    /// A plain-text summary for sharing.
    var plainTextExport: String {
        var lines = [title, "\(category.displayName) · \(priority.displayName) · \(status.displayName)"]
        if !steps.isEmpty {
            lines.append("")
            lines.append(contentsOf: steps.map { "\($0.isDone ? "☑︎" : "☐") \($0.title)" })
        }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            lines.append("")
            lines.append(trimmedNotes)
        }
        return lines.joined(separator: "\n")
    }
}
