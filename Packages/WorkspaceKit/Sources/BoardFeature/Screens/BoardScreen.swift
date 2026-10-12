import SwiftUI

/// A collection's board inside its own navigation stack (one per tab).
public struct BoardScreen: View {
    private let collection: BoardCollection
    @State private var path = NavigationPath()

    public init(collection: BoardCollection) {
        self.collection = collection
    }

    public var body: some View {
        NavigationStack(path: $path) {
            BoardView(collection: collection, path: $path)
        }
    }
}
