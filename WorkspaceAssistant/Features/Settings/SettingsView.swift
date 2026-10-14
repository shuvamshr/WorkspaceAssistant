import SwiftUI

/// The settings sheet: accent theme, layout, list density, assistant and About.
public struct SettingsView: View {
    private let store: WorkspaceStore
    private let assistant: AssistantSettingsInfo?
    @State private var isConfirmingClear = false
    @Environment(\.dismiss) private var dismiss

    public init(store: WorkspaceStore, assistant: AssistantSettingsInfo?) {
        self.store = store
        self.assistant = assistant
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: binding(\.accent, AccentTheme.self, WorkspaceCommand.setAccent)) {
                        ForEach(AccentTheme.allCases) { theme in
                            Label {
                                Text(theme.displayName)
                            } icon: {
                                Image(systemName: "circle.fill").foregroundStyle(theme.color)
                            }
                            .tag(theme)
                        }
                    } label: {
                        Text("Accent Colour")
                    }
                    .pickerStyle(.navigationLink)

                    Picker(selection: binding(\.layout, BoardLayout.self, WorkspaceCommand.setLayout)) {
                        ForEach(BoardLayout.allCases) { layout in
                            Label(layout.displayName, systemImage: layout.symbolName).tag(layout)
                        }
                    } label: {
                        Text("Layout")
                    }

                    Picker(selection: binding(\.listDensity, ListDensity.self, WorkspaceCommand.setListDensity)) {
                        ForEach(ListDensity.allCases) { density in Text(density.displayName).tag(density) }
                    } label: {
                        Text("List Density")
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("You can also switch layouts from the View Options menu on the board.")
                }

                if let assistant {
                    Section {
                        LabeledContent {
                            Text(assistant.status)
                        } label: {
                            Label { Text("Assistant") } icon: { Image(systemName: "sparkles") }
                        }
                        Button(role: .destructive) {
                            isConfirmingClear = true
                        } label: {
                            Text("Clear Conversation")
                        }
                        .disabled(!assistant.hasConversation)
                        .confirmationDialog(
                            Text("Clear the conversation?"),
                            isPresented: $isConfirmingClear,
                            titleVisibility: .visible
                        ) {
                            Button(role: .destructive, action: assistant.clearConversation) {
                                Text("Clear Conversation")
                            }
                        } message: {
                            Text("Your tasks and layout won’t change.")
                        }
                    } header: {
                        Text("Assistant")
                    } footer: {
                        Text(assistant.detail)
                    }
                }

                Section {
                    LabeledContent {
                        Text(Self.version)
                    } label: {
                        Text("Version")
                    }
                    NavigationLink {
                        TileContrastSheet().navigationTitle(Text("Tile Contrast"))
                    } label: {
                        Text("Tile Contrast")
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("The assistant runs entirely on device. Nothing you type leaves your iPhone or iPad.")
                }
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }

    private func binding<Value>(
        _ keyPath: KeyPath<WorkspacePreferences, Value>,
        _: Value.Type,
        _ command: @escaping (Value) -> WorkspaceCommand
    ) -> Binding<Value> {
        Binding(
            get: { store.preferences[keyPath: keyPath] },
            set: { _ = try? store.perform(command($0), actor: .user) }
        )
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(short) (\(build))"
    }
}

#Preview("Light") {
    SettingsView(
        store: WorkspaceStore(repository: InMemoryTaskRepository(), preferencesStore: InMemoryPreferencesStore()),
        assistant: AssistantSettingsInfo(status: "Simulated", detail: "Apple Intelligence isn’t available on this device.", hasConversation: true) {}
    )
}

#Preview("Dark") {
    SettingsView(store: WorkspaceStore(repository: InMemoryTaskRepository(), preferencesStore: InMemoryPreferencesStore()), assistant: nil)
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    SettingsView(store: WorkspaceStore(repository: InMemoryTaskRepository(), preferencesStore: InMemoryPreferencesStore()), assistant: nil)
        .dynamicTypeSize(.accessibility5)
}

#Preview("RTL") {
    SettingsView(store: WorkspaceStore(repository: InMemoryTaskRepository(), preferencesStore: InMemoryPreferencesStore()), assistant: nil)
        .environment(\.layoutDirection, .rightToLeft)
}
