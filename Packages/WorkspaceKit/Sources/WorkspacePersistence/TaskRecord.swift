import Foundation
import SwiftData
import WorkspaceDomain

/// SwiftData storage model for a `TaskItem`.
///
/// Every property has a default and there are no unique constraints, so the schema can later sync
/// through CloudKit. Enums are stored as raw strings and steps as JSON so the domain stays decoupled.
@Model
final class TaskRecord {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var categoryRaw: String = TaskCategory.development.rawValue
    var priorityRaw: String = TaskPriority.normal.rawValue
    var statusRaw: String = TaskStatus.open.rawValue
    var originRaw: String = TaskOrigin.user.rawValue
    var appearanceColorRaw: String?
    var appearanceGlyph: String?
    var stepsData: Data = Data()
    var createdAt: Date = Date.now
    var sortIndex: Double = 0

    init(task: TaskItem) {
        id = task.id
        update(from: task)
    }

    /// Copies every field from a domain task.
    func update(from task: TaskItem) {
        title = task.title
        notes = task.notes
        categoryRaw = task.category.rawValue
        priorityRaw = task.priority.rawValue
        statusRaw = task.status.rawValue
        originRaw = task.origin.rawValue
        appearanceColorRaw = task.appearance?.color.rawValue
        appearanceGlyph = task.appearance?.glyph
        stepsData = (try? JSONEncoder().encode(task.steps)) ?? Data()
        createdAt = task.createdAt
        sortIndex = task.sortIndex
    }

    /// Converts to a domain task, falling back to defaults for unknown raw values.
    var taskItem: TaskItem {
        var appearance: TileAppearance?
        if let raw = appearanceColorRaw, let color = TileColor(rawValue: raw), let glyph = appearanceGlyph {
            appearance = TileAppearance(color: color, glyph: glyph)
        }
        return TaskItem(
            id: id,
            title: title,
            notes: notes,
            category: TaskCategory(rawValue: categoryRaw) ?? .development,
            priority: TaskPriority(rawValue: priorityRaw) ?? .normal,
            status: TaskStatus(rawValue: statusRaw) ?? .open,
            origin: TaskOrigin(rawValue: originRaw) ?? .user,
            appearance: appearance,
            steps: (try? JSONDecoder().decode([TaskStep].self, from: stepsData)) ?? [],
            createdAt: createdAt,
            sortIndex: sortIndex
        )
    }
}
