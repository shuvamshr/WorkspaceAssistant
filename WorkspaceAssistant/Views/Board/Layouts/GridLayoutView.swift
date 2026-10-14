import SwiftUI

/// The default layout: an adaptive grid of Shortcuts-style tiles.
struct GridLayoutView: View {
    let tasks: [TaskItem]
    let namespace: Namespace.ID
    let onOpen: (UUID) -> Void
    @Environment(BoardViewModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(
                    columns: GridMetrics.columns(sizeClass: sizeClass, dynamicTypeSize: dynamicTypeSize),
                    spacing: GridMetrics.spacing
                ) {
                    ForEach(tasks) { task in
                        TaskTileCell(task: task, namespace: namespace, onOpen: onOpen)
                            .dropDestination(for: TaskDragItem.self, isEnabled: model.canReorder) { items, _ in
                                guard let item = items.first else { return }
                                withAnimation(.smooth) { model.drop(item.id, onto: task.id, visible: tasks) }
                            }
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xs)
            }
            .revealsTasks(with: proxy)
        }
    }
}
