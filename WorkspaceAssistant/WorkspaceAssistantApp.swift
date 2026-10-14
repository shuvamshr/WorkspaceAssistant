import SwiftUI

/// App entry point. Owns the composition root and injects dependencies into the environment.
@main
struct WorkspaceAssistantApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if dependencies.launch.showsDesignGallery {
                DesignGallery()
            } else {
                root
            }
            #else
            root
            #endif
        }
        .commands {
            AppCommands(board: dependencies.board, assistant: dependencies.assistant, router: dependencies.router)
        }
    }

    private var root: some View {
        RootView()
            .environment(dependencies.board)
            .environment(dependencies.router)
            .environment(dependencies.assistant)
    }
}
