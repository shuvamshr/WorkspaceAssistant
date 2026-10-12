import WorkspaceDomain

/// The tile colour palette. Base colours are tuned so white text meets WCAG AA (≥ 4.5:1).
///
/// Tiles draw a subtle gradient from `top` (lighter, used behind the glyph) down to `base` (behind the title).
/// With Increase Contrast, tiles use the solid, darker `highContrast` colour instead.
nonisolated public enum TilePalette {
    /// How much white is blended into the top of the gradient.
    public static let topLightening = 0.18
    /// How much black is blended in for Increase Contrast.
    public static let highContrastDarkening = 0.22

    /// Base colour (bottom of the gradient, behind text).
    public static func base(_ color: TileColor) -> RGB {
        switch color {
        case .red: RGB(hex: 0xD7263A)
        case .orange: RGB(hex: 0xC24E00)
        case .yellow: RGB(hex: 0xA16207)
        case .green: RGB(hex: 0x1E7E34)
        case .mint: RGB(hex: 0x0A7C6A)
        case .teal: RGB(hex: 0x0B7585)
        case .cyan: RGB(hex: 0x056EA6)
        case .blue: RGB(hex: 0x1A5FD6)
        case .indigo: RGB(hex: 0x4B3FD1)
        case .purple: RGB(hex: 0x8A3FC4)
        case .pink: RGB(hex: 0xC7246E)
        case .gray: RGB(hex: 0x5E636E)
        }
    }

    /// Lighter top of the gradient (behind the glyph; large graphics need ≥ 3:1).
    public static func top(_ color: TileColor) -> RGB {
        base(color).mixed(with: .white, by: topLightening)
    }

    /// Solid colour used when Increase Contrast is on.
    public static func highContrast(_ color: TileColor) -> RGB {
        base(color).mixed(with: .black, by: highContrastDarkening)
    }
}
