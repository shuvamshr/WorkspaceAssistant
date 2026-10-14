import SwiftUI

/// Grid sizing for tile layouts.
nonisolated public enum GridMetrics {
    /// Minimum tile width for compact width (iPhone).
    public static let compactMinTileWidth: CGFloat = 160
    /// Minimum tile width for regular width (iPad).
    public static let regularMinTileWidth: CGFloat = 180
    /// Spacing between tiles.
    public static let spacing: CGFloat = Spacing.s

    /// Adaptive grid columns; collapses to a single column at accessibility text sizes.
    public static func columns(sizeClass: UserInterfaceSizeClass?, dynamicTypeSize: DynamicTypeSize) -> [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: spacing)]
        }
        let minimum = sizeClass == .regular ? regularMinTileWidth : compactMinTileWidth
        return [GridItem(.adaptive(minimum: minimum), spacing: spacing)]
    }
}
