/// A tile's colour and SF Symbol glyph, like a Shortcut's icon.
public struct TileAppearance: Hashable, Codable, Sendable {
    /// Tile background colour.
    public var color: TileColor
    /// SF Symbol name drawn on the tile.
    public var glyph: String

    public init(color: TileColor, glyph: String) {
        self.color = color
        self.glyph = glyph
    }
}
