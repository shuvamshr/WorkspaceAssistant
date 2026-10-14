/// The kind of work a task represents. Each category has a default tile appearance.
public enum TaskCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case development, testing, design, operations

    public var id: String { rawValue }

    /// Default colour and glyph for tiles in this category (overridable per task).
    public var defaultAppearance: TileAppearance {
        switch self {
        case .development: TileAppearance(color: .blue, glyph: "hammer.fill")
        case .testing: TileAppearance(color: .green, glyph: "checkmark.seal.fill")
        case .design: TileAppearance(color: .pink, glyph: "paintbrush.pointed.fill")
        case .operations: TileAppearance(color: .orange, glyph: "gearshape.2.fill")
        }
    }
}
