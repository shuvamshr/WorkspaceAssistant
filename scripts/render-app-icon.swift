import AppKit
import CoreGraphics

// Renders the app icon. Usage: swift scripts/render-app-icon.swift <out.png> <withBackground: 1|0>
let size: CGFloat = 1024
let withBackground = CommandLine.arguments[2] == "1"
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: (withBackground ? CGImageAlphaInfo.noneSkipLast : CGImageAlphaInfo.premultipliedLast).rawValue)!

let indigo = CGColor(srgbRed: 0x4B / 255, green: 0x3F / 255, blue: 0xD1 / 255, alpha: 1)
let white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)

if withBackground {
    ctx.setFillColor(indigo)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
}

// 2×2 grid centred in the icon, sized to sit comfortably inside the iOS icon mask.
let tile: CGFloat = 232
let gap: CGFloat = 56
let corner: CGFloat = 64
let origin = (size - (tile * 2 + gap)) / 2
ctx.setFillColor(white)

func tileRect(col: Int, row: Int) -> CGRect {
    // CoreGraphics origin is bottom-left; row 0 = top.
    CGRect(x: origin + CGFloat(col) * (tile + gap),
           y: size - origin - tile - CGFloat(row) * (tile + gap),
           width: tile, height: tile)
}

for (col, row) in [(0, 0), (0, 1), (1, 1)] {
    ctx.addPath(CGPath(roundedRect: tileRect(col: col, row: row), cornerWidth: corner, cornerHeight: corner, transform: nil))
    ctx.fillPath()
}

// Four-point sparkle in the top-right slot (custom path; SF Symbols can't be used in app icons).
let slot = tileRect(col: 1, row: 0)
let c = CGPoint(x: slot.midX, y: slot.midY)
let r = tile * 0.56          // reach of each point
let pinch = tile * 0.075     // how close the curves pass to the centre
let star = CGMutablePath()
let points = [CGPoint(x: c.x, y: c.y + r), CGPoint(x: c.x + r, y: c.y), CGPoint(x: c.x, y: c.y - r), CGPoint(x: c.x - r, y: c.y)]
let controls = [CGPoint(x: c.x + pinch, y: c.y + pinch), CGPoint(x: c.x + pinch, y: c.y - pinch),
                CGPoint(x: c.x - pinch, y: c.y - pinch), CGPoint(x: c.x - pinch, y: c.y + pinch)]
star.move(to: points[0])
for i in 0..<4 {
    star.addQuadCurve(to: points[(i + 1) % 4], control: controls[i])
}
star.closeSubpath()
ctx.addPath(star)
ctx.fillPath()

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
