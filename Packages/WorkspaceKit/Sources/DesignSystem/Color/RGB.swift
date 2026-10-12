import SwiftUI

/// An sRGB colour with WCAG luminance and contrast helpers.
nonisolated public struct RGB: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    /// Creates a colour from a 24-bit hex value, e.g. `0x1A5FD6`.
    public init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static let white = RGB(red: 1, green: 1, blue: 1)
    public static let black = RGB(red: 0, green: 0, blue: 0)

    /// WCAG relative luminance.
    public var luminance: Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    /// WCAG contrast ratio between two colours (1…21).
    public func contrast(with other: RGB) -> Double {
        let (lighter, darker) = luminance > other.luminance ? (luminance, other.luminance) : (other.luminance, luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Linear blend toward `other` by `amount` (0…1).
    public func mixed(with other: RGB, by amount: Double) -> RGB {
        RGB(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount
        )
    }

    /// SwiftUI colour.
    public var color: Color { Color(.sRGB, red: red, green: green, blue: blue) }
}
