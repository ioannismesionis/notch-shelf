import AppKit
import Foundation

let iconsetURL = URL(fileURLWithPath: "Packaging/AppIcon.iconset")
let fileManager = FileManager.default

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let variants: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for variant in variants {
    let image = renderIcon(size: variant.pixels)
    let outputURL = iconsetURL.appendingPathComponent(variant.name)
    try pngData(from: image)?.write(to: outputURL)
}

private func renderIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let scale = CGFloat(size) / 1024

    NSColor.clear.setFill()
    bounds.fill()

    let background = NSBezierPath(roundedRect: bounds.insetBy(dx: 72 * scale, dy: 72 * scale), xRadius: 220 * scale, yRadius: 220 * scale)
    NSGradient(colors: [
        NSColor(calibratedWhite: 0.13, alpha: 1),
        NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.07, alpha: 1)
    ])?.draw(in: background, angle: -45)

    NSColor(calibratedWhite: 1, alpha: 0.10).setStroke()
    background.lineWidth = 10 * scale
    background.stroke()

    let notchRect = NSRect(x: 252 * scale, y: 660 * scale, width: 520 * scale, height: 132 * scale)
    let notch = NSBezierPath(roundedRect: notchRect, xRadius: 58 * scale, yRadius: 58 * scale)
    NSColor(calibratedWhite: 0.01, alpha: 0.88).setFill()
    notch.fill()

    let shelfRect = NSRect(x: 202 * scale, y: 270 * scale, width: 620 * scale, height: 330 * scale)
    let shelf = NSBezierPath(roundedRect: shelfRect, xRadius: 108 * scale, yRadius: 108 * scale)
    NSColor(calibratedWhite: 1, alpha: 0.14).setFill()
    shelf.fill()
    NSColor(calibratedWhite: 1, alpha: 0.18).setStroke()
    shelf.lineWidth = 8 * scale
    shelf.stroke()

    let circleRect = NSRect(x: 328 * scale, y: 338 * scale, width: 236 * scale, height: 236 * scale)
    NSColor(calibratedRed: 0.10, green: 0.84, blue: 0.38, alpha: 1).setFill()
    NSBezierPath(ovalIn: circleRect).fill()

    drawWave(in: NSRect(x: 390 * scale, y: 492 * scale, width: 112 * scale, height: 28 * scale), scale: scale)
    drawWave(in: NSRect(x: 380 * scale, y: 440 * scale, width: 132 * scale, height: 34 * scale), scale: scale)
    drawWave(in: NSRect(x: 372 * scale, y: 386 * scale, width: 148 * scale, height: 38 * scale), scale: scale)

    let play = NSBezierPath()
    play.move(to: NSPoint(x: 608 * scale, y: 360 * scale))
    play.line(to: NSPoint(x: 608 * scale, y: 548 * scale))
    play.line(to: NSPoint(x: 744 * scale, y: 454 * scale))
    play.close()
    NSColor.white.withAlphaComponent(0.94).setFill()
    play.fill()

    image.unlockFocus()
    return image
}

private func drawWave(in rect: NSRect, scale: CGFloat) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: rect.minX, y: rect.midY - rect.height * 0.12))
    path.curve(
        to: NSPoint(x: rect.maxX, y: rect.midY - rect.height * 0.18),
        controlPoint1: NSPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY),
        controlPoint2: NSPoint(x: rect.minX + rect.width * 0.66, y: rect.minY)
    )
    NSColor.black.withAlphaComponent(0.82).setStroke()
    path.lineWidth = max(2, 16 * scale)
    path.lineCapStyle = .round
    path.stroke()
}

private func pngData(from image: NSImage) -> Data? {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData) else {
        return nil
    }

    return bitmap.representation(using: .png, properties: [:])
}
