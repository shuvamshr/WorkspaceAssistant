import DesignSystem
import SwiftUI
import WorkspaceDomain

/// Priority tasks as large tiles, with everything else as compact rows below.
struct FocusLayoutView: View {
    let tasks: [TaskItem]
    let namespace: Namespace.ID
    let onOpen: (UUID) -> Void
    @Environment(BoardModel.self) private var model

    private var priority: [TaskItem] { tasks.filter(\.isHighPriority) }
    private var others: [TaskItem] { tasks.filter { !$0.isHighPriority } }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.s) {
                    if priority.isEmpty {
                        ContentUnavailableView {
                            Label { Text("No Priority Tasks", bundle: .module) } icon: { Image(systemName: "star") }
                        } description: {
                            Text("Prioritise the tasks that matter most and they’ll appear here.", bundle: .module)
                        } actions: {
                            Button {
                                model.isSelecting = true
                            } label: {
                                Text("Choose Tasks…", bundle: .module)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ForEach(priority) { task in
                            TaskTileCell(task: task, size: .large, namespace: namespace, onOpen: onOpen)
                        }
                    }

                    if !others.isEmpty {
                        Text("Everything Else", bundle: .module)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, Spacing.m)
                        VStack(spacing: 0) {
                            ForEach(others) { task in
                                compactRow(task)
                                if task.id != others.last?.id { Divider().padding(.leading, 56) }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground), in: Radius.blockShape)
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xs)
            }
            .revealsTasks(with: proxy)
        }
    }

    private func compactRow(_ task: TaskItem) -> some View {
        Button {
            if model.isSelecting { model.toggleSelection(task.id) } else { onOpen(task.id) }
        } label: {
            HStack {
                if model.isSelecting {
                    Image(systemName: model.selection.contains(task.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(model.selection.contains(task.id) ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        .accessibilityHidden(true)
                }
                TaskRow(task: task, density: .compact, highlightTrigger: model.highlightTrigger(for: task.id))
            }
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .contextMenu { TaskMenuItems(task: task) } preview: { TaskTile(task: task, size: .large).frame(width: 320) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(model.isSelecting && model.selection.contains(task.id) ? .isSelected : [])
        .taskAccessibilityActions(task) { onOpen(task.id) }
        .id(task.id)
    }
}
