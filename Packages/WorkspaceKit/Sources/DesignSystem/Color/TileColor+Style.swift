import SwiftUI
import WorkspaceDomain

extension TileColor {
    /// The tile's base colour.
    public var color: Color { TilePalette.base(self).color }

    /// Foreground for text and glyphs on this tile. White meets AA on every palette colour.
    public var foreground: Color { .white }

    /// The tile background style, respecting Increase Contrast.
    public func background(contrast: ColorSchemeContrast) -> AnyShapeStyle {
        if contrast == .increased {
            return AnyShapeStyle(TilePalette.highContrast(self).color)
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
        case .red: String(localized: "Red", bundle: .module)
        case .orange: String(localized: "Orange", bundle: .module)
        case .yellow: String(localized: "Yellow", bundle: .module)
        case .green: String(localized: "Green", bundle: .module)
        case .mint: String(localized: "Mint", bundle: .module)
        case .teal: String(localized: "Teal", bundle: .module)
        case .cyan: String(localized: "Cyan", bundle: .module)
        case .blue: String(localized: "Blue", bundle: .module)
        case .indigo: String(localized: "Indigo", bundle: .module)
        case .purple: String(localized: "Purple", bundle: .module)
        case .pink: String(localized: "Pink", bundle: .module)
        case .gray: String(localized: "Gray", bundle: .module)
        }
    }
}
