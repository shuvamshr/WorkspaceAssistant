import BoardFeature
import DesignSystem
import SwiftUI

/// App entry point. Owns the composition root and injects dependencies into the environment.
@main
struct WorkspaceAssistantApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            if dependencies.launch.showsDesignGallery {
                DesignGallery()
            } else {
                RootView()
                    .environment(dependencies.board)
                    .environment(dependencies.router)
            }
        }
        .commands {
            AppCommands(board: dependencies.board, router: dependencies.router)
        }
    }
}
