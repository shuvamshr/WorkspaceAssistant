import DesignSystem
import SwiftUI
import WorkspaceDomain

/// Priority / Backlog / Done columns of mini tiles. Side by side on regular width;
/// horizontally paging columns on compact width. Drag between columns to change priority or status.
struct KanbanLayoutView: View {
    let tasks: [TaskItem]
    let namespace: Namespace.ID
    let onOpen: (UUID) -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if sizeClass == .regular && !dynamicTypeSize.isAccessibilitySize {
            ScrollViewReader { proxy in
                ScrollView {
                    HStack(alignment: .top, spacing: Spacing.m) {
                        ForEach(BoardColumn.allCases) { column in
                            KanbanColumnView(column: column, tasks: tasks(in: column), namespace: namespace, onOpen: onOpen, scrolls: false)
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xs)
                }
                .revealsTasks(with: proxy)
            }
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(BoardColumn.allCases) { column in
                        KanbanColumnView(column: column, tasks: tasks(in: column), namespace: namespace, onOpen: onOpen, scrolls: true)
                            .padding(.trailing, Spacing.s)
                            // Columns are slightly narrower than the screen so the next one peeks in.
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.88 }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, Spacing.m, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .scrollIndicators(.hidden)
        }
    }

    private func tasks(in column: BoardColumn) -> [TaskItem] {
        tasks.filter { BoardColumn.of($0) == column }
    }
}

/// One Board column with a header and a drop target.
struct KanbanColumnView: View {
    let column: BoardColumn
    let tasks: [TaskItem]
    let namespace: Namespace.ID
    let onOpen: (UUID) -> Void
    /// Whether the column scrolls on its own (compact paging mode) with a sticky header.
    let scrolls: Bool
    @Environment(BoardModel.self) private var model
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            header
            if scrolls {
                ScrollViewReader { proxy in
                    ScrollView { cards }
                        .revealsTasks(with: proxy)
                }
            } else {
                cards
            }
        }
        .frame(maxWidth: .infinity, maxHeight: scrolls ? .infinity : nil, alignment: .top)
        .padding(Spacing.s)
        .background(isTargeted ? AnyShapeStyle(.tint.opacity(0.12)) : AnyShapeStyle(Color(.secondarySystemGroupedBackground).opacity(0.6)), in: Radius.blockShape)
        .dropDestination(for: TaskDragItem.self) { items, _ in
            for item in items { withAnimation(.smooth) { model.drop(item.id, into: column) } }
            return !items.isEmpty
        } isTargeted: { isTargeted = $0 }
    }

    private var header: some View {
        HStack {
            Text(column.title).font(.headline)
            Text(tasks.count, format: .number)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder private var cards: some View {
        LazyVStack(spacing: Spacing.xs) {
            ForEach(tasks) { task in
                TaskTileCell(task: task, size: .mini, namespace: namespace, onOpen: onOpen)
            }
            if tasks.isEmpty {
                Text("Drop tasks here", bundle: .module)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .overlay { Radius.blockShape.strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1.5, dash: [5])) }
            }
        }
    }
}
