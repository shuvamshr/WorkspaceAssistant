import BoardFeature
import Foundation
import os
import WorkspaceDomain
import WorkspacePersistence

/// Composition root: builds storage, the store and feature models once per launch.
@MainActor
final class AppDependencies {
    let store: WorkspaceStore
    let board: BoardModel
    let router = AppRouter()
    let launch: LaunchConfiguration

    init(launch: LaunchConfiguration = LaunchConfiguration()) {
        self.launch = launch
        let repository: any TaskRepository
        let preferences: any PreferencesStore
        if launch.usesEphemeralStorage {
            repository = InMemoryTaskRepository()
            preferences = InMemoryPreferencesStore()
        } else {
            do {
                repository = try SwiftDataTaskRepository()
            } catch {
                Log.persistence.fault("Falling back to in-memory storage: \(error.localizedDescription, privacy: .public)")
                repository = InMemoryTaskRepository()
            }
            preferences = UserDefaultsPreferencesStore()
        }
        store = WorkspaceStore(repository: repository, preferencesStore: preferences)
        store.undoActionName = UndoActionNames.name(for:)
        board = BoardModel(store: store)
    }
}
