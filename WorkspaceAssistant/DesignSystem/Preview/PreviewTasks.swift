import Foundation
import SwiftUI

/// Sample tasks for previews.
enum PreviewTasks {
    static let all: [TaskItem] = {
        var tasks = SampleData.tasks()
        tasks[0].priority = .high
        tasks[2].origin = .assistant
        tasks[3].status = .done
        tasks[4].appearance = TileAppearance(color: .purple, glyph: "ladybug.fill")
        tasks[4].notes = "Instruments shows retained cells after scrolling."
        return tasks
    }()

    static var highPriority: TaskItem { all[0] }
}

/// A small grid of tiles in every size, for previews.
struct TileGalleryPreview: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVGrid(columns: GridMetrics.columns(sizeClass: sizeClass, dynamicTypeSize: dynamicTypeSize), spacing: 12) {
                ForEach(PreviewTasks.all) { TaskTile(task: $0) }
            }
            TaskTile(task: PreviewTasks.highPriority, size: .large).padding(.vertical)
            ViewThatFits {
                HStack {
                    TaskTile(task: PreviewTasks.all[1], size: .mini)
                    TaskTile(task: PreviewTasks.all[3], size: .mini, isSelected: true)
                }
                VStack {
                    TaskTile(task: PreviewTasks.all[1], size: .mini)
                    TaskTile(task: PreviewTasks.all[3], size: .mini, isSelected: true)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
