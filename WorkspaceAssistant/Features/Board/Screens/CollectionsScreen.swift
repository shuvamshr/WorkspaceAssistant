import SwiftUI

/// The Collections tab on iPhone: Priority, Done and one per category.
public struct CollectionsScreen: View {
    @State private var path = NavigationPath()
    @Environment(BoardModel.self) private var model

    public init() {}

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(BoardCollection.allCases.filter { $0 != .all }) { collection in
                        NavigationLink(value: collection) {
                            HStack(spacing: Spacing.s) {
                                GlyphSquare(glyph: collection.symbolName, color: collection.color, size: .medium)
                                Text(collection.title)
                                Spacer()
                                Text(model.count(in: collection), format: .number)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .navigationTitle(Text("Collections"))
            .navigationDestination(for: BoardCollection.self) { collection in
                BoardView(collection: collection, path: $path)
            }
        }
    }
}
