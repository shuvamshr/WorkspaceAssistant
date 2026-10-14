import SwiftUI

extension TileColor {
    /// The tile's base colour.
    public var color: Color { TilePalette.base(self).color }

    /// Foreground for text and glyphs on this tile. White meets AA on every palette colour.
    public var foreground: Color { .white }

    /// The tile background style, respecting Increase Contrast.
    /// - Parameter solid: Use the base colour without a gradient (for short tiles whose text sits near the top).
    public func background(contrast: ColorSchemeContrast, solid: Bool = false) -> AnyShapeStyle {
        if contrast == .increased {
            return AnyShapeStyle(TilePalette.highContrast(self).color)
        }
        if solid {
            return AnyShapeStyle(TilePalette.base(self).color)
        }
        return AnyShapeStyle(
            LinearGradient(
                stops: [
                    .init(color: TilePalette.top(self).color, location: 0),
                    .init(color: TilePalette.base(self).color, location: 0.55),
                    .init(color: TilePalette.base(self).color, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    /// Localised colour name.
    public var displayName: String {
        switch self {
        case .red: String(localized: "Red")
        case .orange: String(localized: "Orange")
        case .yellow: String(localized: "Yellow")
        case .green: String(localized: "Green")
        case .mint: String(localized: "Mint")
        case .teal: String(localized: "Teal")
        case .cyan: String(localized: "Cyan")
        case .blue: String(localized: "Blue")
        case .indigo: String(localized: "Indigo")
        case .purple: String(localized: "Purple")
        case .pink: String(localized: "Pink")
        case .gray: String(localized: "Gray")
        }
    }
}
