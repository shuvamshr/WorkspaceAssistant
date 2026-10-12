import DesignSystem
import SwiftUI
import WorkspaceDomain

/// App entry point and composition root.
@main
struct WorkspaceAssistantApp: App {
    private let arguments = ProcessInfo.processInfo.arguments

    var body: some Scene {
        WindowGroup {
            if arguments.contains("-DesignGallery") {
                DesignGallery()
                    .dynamicTypeSize(arguments.contains("-GalleryAX5") ? .accessibility5 : .large)
                    .environment(\.layoutDirection, arguments.contains("-GalleryRTL") ? .rightToLeft : .leftToRight)
            } else {
                Text("Workspace")
            }
        }
    }
}
