import SwiftUI

/// The board for one collection: the current layout, toolbar, selection bar and detail navigation.
/// Embed inside a `NavigationStack`; push `TaskRoute` values to open tasks.
public struct BoardView: View {
    private let collection: BoardCollection
    @Binding private var path: NavigationPath
    @Environment(BoardModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var namespace

    public init(collection: BoardCollection, path: Binding<NavigationPath>) {
        self.collection = collection
        _path = path
    }

    private var layout: BoardLayout { model.store.preferences.layout }

    public var body: some View {
        let tasks = model.tasks(in: collection)
        content(tasks)
            .id(layout)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth, value: layout)
            .animation(reduceMotion ? nil : .smooth, value: tasks)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(collection.title)
            .toolbar { BoardToolbar(collection: collection) }
            .toolbar(model.isSelecting ? .hidden : .automatic, for: .tabBar)
            .navigationDestination(for: TaskRoute.self) { route in
                TaskDetailView(taskID: route.taskID) { path.removeLast(path.count) }
                    .navigationTransition(.zoom(sourceID: route.taskID, in: namespace)) // The system cross-fades under Reduce Motion.
            }
            .sensoryFeedback(trigger: model.store.tasks.count(where: \.isDone)) { old, new in
                new > old ? .success : nil
            }
            .sensoryFeedback(.impact(weight: .light), trigger: model.store.tasks.count(where: \.isHighPriority))
    }

    @ViewBuilder private func content(_ tasks: [TaskItem]) -> some View {
        if tasks.isEmpty && layout != .board && layout != .focus {
            emptyState
        } else {
            switch layout {
            case .grid: GridLayoutView(tasks: tasks, namespace: namespace, onOpen: open)
            case .list: ListLayoutView(tasks: tasks, onOpen: open)
            case .focus: FocusLayoutView(tasks: tasks, namespace: namespace, onOpen: open)
            case .board: KanbanLayoutView(tasks: tasks, namespace: namespace, onOpen: open)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: collection.symbolName)
        } description: {
            Text(emptyMessage)
        } actions: {
            if collection != .done {
                Button {
                    model.createTask(in: collection)
                } label: {
                    Text("New Task")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var emptyTitle: String {
        switch collection {
        case .done: String(localized: "Nothing Done Yet")
        case .priority: String(localized: "No Priority Tasks")
        default: String(localized: "No Tasks")
        }
    }

    private var emptyMessage: String {
        switch collection {
        case .done: String(localized: "Completed tasks appear here.")
        case .priority: String(localized: "Prioritise a task to see it here.")
        default: String(localized: "Add a task, or ask the assistant to create one.")
        }
    }

    private func open(_ id: UUID) {
        path.append(TaskRoute(taskID: id))
    }
}
