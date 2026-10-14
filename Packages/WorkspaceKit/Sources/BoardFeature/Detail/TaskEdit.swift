import Foundation
import WorkspaceDomain

/// An edit made in the task editor. Applied directly to a draft, or turned into a command for a stored task.
enum TaskEdit: Equatable {
    case title(String)
    case notes(String)
    case category(TaskCategory)
    case priority(TaskPriority)
    case status(TaskStatus)
    case appearance(TileAppearance?)
    case addStep(String)
    case toggleStep(UUID)
    case renameStep(UUID, String)
    case deleteSteps(IndexSet)
    case moveSteps(IndexSet, Int)

    /// Applies the edit to a draft task in place.
    func apply(to task: inout TaskItem) {
        switch self {
        case let .title(title): task.title = title
        case let .notes(notes): task.notes = notes
        case let .category(category): task.category = category
        case let .priority(priority): task.priority = priority
        case let .status(status): task.status = status
        case let .appearance(appearance): task.appearance = appearance
        case let .addStep(title):
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { task.steps.append(TaskStep(title: trimmed)) }
        case let .toggleStep(id):
            if let index = task.steps.firstIndex(where: { $0.id == id }) { task.steps[index].isDone.toggle() }
        case let .renameStep(id, title):
            if let index = task.steps.firstIndex(where: { $0.id == id }) { task.steps[index].title = title }
        case let .deleteSteps(offsets):
            task.steps = task.steps.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
        case let .moveSteps(offsets, destination):
            task.steps.moveElements(fromOffsets: offsets, toOffset: destination)
        }
    }

    /// The commands that perform this edit on a stored task.
    func commands(for task: TaskItem) -> [WorkspaceCommand] {
        let id = task.id
        switch self {
        case let .title(title): return [.updateTask(id: id, changes: TaskChanges(title: title))]
        case let .notes(notes): return [.updateTask(id: id, changes: TaskChanges(notes: notes))]
        case let .category(category): return [.updateTask(id: id, changes: TaskChanges(category: category))]
        case let .priority(priority): return [.setPriority(ids: [id], priority)]
        case let .status(status): return [.setStatus(ids: [id], status)]
        case let .appearance(appearance): return [.setAppearance(id: id, appearance)]
        case let .addStep(title): return [.addStep(taskID: id, title: title)]
        case let .toggleStep(stepID): return [.toggleStep(taskID: id, stepID: stepID)]
        case let .renameStep(stepID, title): return [.renameStep(taskID: id, stepID: stepID, title: title)]
        case let .deleteSteps(offsets):
            return offsets.compactMap { task.steps.indices.contains($0) ? task.steps[$0].id : nil }
                .map { .deleteStep(taskID: id, stepID: $0) }
        case let .moveSteps(offsets, destination): return [.moveSteps(taskID: id, fromOffsets: offsets, toOffset: destination)]
        }
    }
}
