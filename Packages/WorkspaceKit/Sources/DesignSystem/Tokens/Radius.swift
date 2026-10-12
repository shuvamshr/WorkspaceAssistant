import SwiftUI

/// Corner radii. Always used with continuous rounded rectangles.
nonisolated public enum Radius {
    public static let tile: CGFloat = 20
    public static let block: CGFloat = 14
    public static let chip: CGFloat = 8

    /// Continuous rounded rectangle for a tile.
    public static var tileShape: RoundedRectangle { RoundedRectangle(cornerRadius: tile, style: .continuous) }
    /// Continuous rounded rectangle for a block.
    public static var blockShape: RoundedRectangle { RoundedRectangle(cornerRadius: block, style: .continuous) }
    /// Continuous rounded rectangle for a chip or token.
    public static var chipShape: RoundedRectangle { RoundedRectangle(cornerRadius: chip, style: .continuous) }
}
