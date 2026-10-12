import DesignSystem
import SwiftUI
import WorkspaceDomain

/// The scrolling transcript. Always keeps a bottom anchor so new entries scroll reliably into view.
struct TranscriptView<Header: View>: View {
    let items: [TranscriptItem]
    let onSelectTask: (UUID) -> Void
    @ViewBuilder let header: () -> Header
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let bottomID = "transcript-bottom"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.s) {
                    header()
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if TranscriptTimestamps.shows(at: index, in: items) {
                            Text(item.date, format: .dateTime.weekday().hour().minute())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, Spacing.xs)
                        }
                        TranscriptRow(item: item, isLatestAction: item.id == latestActionID, onSelectTask: onSelectTask)
                            .id(item.id)
                    }
                    Color.clear.frame(height: 1).id(bottomID)
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { proxy.scrollTo(bottomID, anchor: .bottom) }
            .onChange(of: items) {
                withAnimation(reduceMotion ? nil : .smooth) { proxy.scrollTo(bottomID, anchor: .bottom) }
            }
        }
    }

    private var latestActionID: UUID? {
        items.last { if case .action = $0.content { true } else { false } }?.id
    }
}

/// When the transcript shows a timestamp.
enum TranscriptTimestamps {
    /// Gap after which a timestamp is shown.
    static let gap: TimeInterval = 5 * 60

    /// Whether to show a timestamp before the item at `index`: first item, or after a 5-minute gap.
    static func shows(at index: Int, in items: [TranscriptItem]) -> Bool {
        guard index > 0 else { return true }
        return items[index].date.timeIntervalSince(items[index - 1].date) >= gap
    }
}
