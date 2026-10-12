import SwiftUI
import WorkspaceDomain

/// A gallery of design-system components for visual review on device or simulator.
/// The app shows it when launched with `-DesignGallery`, optionally with `-GalleryAX5` or `-GalleryRTL`.
public struct DesignGallery: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    TileGalleryPreview()
                    VStack(spacing: Spacing.xs) {
                        ForEach(PreviewTasks.all.prefix(3)) { task in
                            TaskRow(task: task).padding(.horizontal).padding(.vertical, Spacing.xs)
                                .background(Color(.secondarySystemGroupedBackground), in: Radius.blockShape)
                        }
                    }
                    .padding(.horizontal)
                    VStack(spacing: Spacing.s) {
                        ActionBlock(glyph: "star.fill", color: .orange, parts: [.verb("Prioritise"), .token("Refactor Network Layer")], accessibilitySentence: "")
                        ActionBlock(glyph: "star.fill", color: .orange, parts: [.verb("Prioritise"), .token("pipeline-x")], failureReason: "No task matches “pipeline-x”.", accessibilitySentence: "")
                        StepBlock(isDone: true, onToggle: {}) { Text(verbatim: "Audit URLSession call sites") }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text(verbatim: "Design Gallery"))
            .toolbar {
                NavigationLink {
                    TileContrastSheet()
                } label: {
                    Image(systemName: "circle.lefthalf.filled")
                }
            }
        }
    }
}
