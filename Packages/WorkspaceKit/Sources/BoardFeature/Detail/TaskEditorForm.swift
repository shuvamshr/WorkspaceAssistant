import DesignSystem
import SwiftUI
import WorkspaceDomain

/// The block-based task editor shared by the detail view and the new-task sheet.
struct TaskEditorForm: View {
    let task: TaskItem
    /// When `true`, title and notes are applied on every keystroke (drafts); otherwise on commit.
    let commitsLive: Bool
    let apply: (TaskEdit) -> Void
    let onEditAppearance: () -> Void

    private enum Field: Hashable { case title, notes, newStep }

    @State private var title = ""
    @State private var notes = ""
    @State private var newStep = ""
    @FocusState private var focus: Field?

    var body: some View {
        List {
            Section { header }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

            Section {
                Picker(selection: Binding(get: { task.category }, set: { apply(.category($0)) })) {
                    ForEach(TaskCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.symbolName).tag(category)
                    }
                } label: {
                    Label { Text("Category", bundle: .module) } icon: { Image(systemName: "folder") }
                }
                .pickerStyle(.menu)

                Toggle(isOn: Binding(get: { task.isHighPriority }, set: { apply(.priority($0 ? .high : .normal)) })) {
                    Label { Text("High Priority", bundle: .module) } icon: { Image(systemName: task.isHighPriority ? "star.fill" : "star") }
                }

                Toggle(isOn: Binding(get: { task.isDone }, set: { apply(.status($0 ? .done : .open)) })) {
                    Label { Text("Completed", bundle: .module) } icon: { Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle") }
                }
            } header: {
                Text("Details", bundle: .module)
            }

            Section {
                ForEach(task.steps) { step in
                    StepBlock(isDone: step.isDone, onToggle: { apply(.toggleStep(step.id)) }) {
                        StepTitleField(step: step) { apply(.renameStep(step.id, $0)) }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: Spacing.xxs, leading: 0, bottom: Spacing.xxs, trailing: 0))
                }
                .onMove { apply(.moveSteps($0, $1)) }
                .onDelete { apply(.deleteSteps($0)) }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                    TextField(text: $newStep) { Text("Add Step", bundle: .module) }
                        .focused($focus, equals: .newStep)
                        .submitLabel(.next)
                        .onSubmit(addStep)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            } header: {
                Text("Steps", bundle: .module)
            }

            Section {
                TextField(text: $notes, axis: .vertical) { Text("Add notes", bundle: .module) }
                    .lineLimit(4...)
                    .focused($focus, equals: .notes)
                    .onChange(of: notes) { _, value in if commitsLive { apply(.notes(value)) } }
            } header: {
                Text("Notes", bundle: .module)
            }

            Section {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Created \(task.createdAt.formatted(date: .abbreviated, time: .shortened))", bundle: .module)
                    if task.origin == .assistant {
                        Label { Text("Added by Assistant", bundle: .module) } icon: { Image(systemName: "sparkles") }
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                .accessibilityElement(children: .combine)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            title = task.title
            notes = task.notes
        }
        .onChange(of: task.title) { _, value in if focus != .title { title = value } }
        .onChange(of: task.notes) { _, value in if focus != .notes { notes = value } }
        .onChange(of: focus) { old, _ in
            if old == .title { commitTitle() }
            if old == .notes { commitNotes() }
        }
        .onDisappear {
            commitTitle()
            commitNotes()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            Button(action: onEditAppearance) {
                GlyphSquare(task.resolvedAppearance, size: .large)
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityLabel(Text("Edit Appearance", bundle: .module))
            .accessibilityHint(Text("Changes the tile colour and glyph", bundle: .module))

            TextField(text: $title, axis: .vertical) { Text("Title", bundle: .module) }
                .font(.title2.bold())
                .lineLimit(1...4)
                .focused($focus, equals: .title)
                .submitLabel(.done)
                .onSubmit { focus = nil }
                .onChange(of: title) { _, value in if commitsLive { apply(.title(value)) } }
                .accessibilityLabel(Text("Title", bundle: .module))
                .accessibilityIdentifier("taskTitleField")
        }
        .padding(.vertical, Spacing.s)
    }

    private func commitTitle() {
        guard !commitsLive else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            title = task.title
        } else if trimmed != task.title {
            apply(.title(trimmed))
        }
    }

    private func commitNotes() {
        guard !commitsLive, notes != task.notes else { return }
        apply(.notes(notes))
    }

    private func addStep() {
        let trimmed = newStep.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        apply(.addStep(trimmed))
        newStep = ""
        focus = .newStep
    }
}
