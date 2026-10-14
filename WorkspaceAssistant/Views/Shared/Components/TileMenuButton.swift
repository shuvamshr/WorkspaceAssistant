import SwiftUI

/// The "⋯" button in a tile's top-trailing corner. 44×44pt hit target.
///
/// Overlay it on a tile as a sibling of the tile's button (not inside it) so taps don't conflict.
public struct TileMenuButton<Content: View>: View {
    private let content: Content
    @ScaledMetric(relativeTo: .body) private var circle: CGFloat = 28

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        Menu {
            content
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: circle, height: circle)
                .background(.black.opacity(0.18), in: Circle())
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel(Text("More Actions"))
    }
}
