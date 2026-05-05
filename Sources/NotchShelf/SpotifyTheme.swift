import AppKit
import SwiftUI

struct SpotifyTheme {
    let surfaceTop: Color
    let surfaceMiddle: Color
    let surfaceBottom: Color
    let cardBackground: Color
    let cardBorder: Color
    let controlBackground: Color
    let controlHoverBackground: Color
    let primaryControlBackground: Color
    let primaryControlForeground: Color
    let progressFill: Color
    let iconTileBackground: Color

    static let fallback = SpotifyTheme(
        surfaceTop: Color.white.opacity(0.13),
        surfaceMiddle: Color(red: 0.18, green: 0.19, blue: 0.20).opacity(0.30),
        surfaceBottom: Color.black.opacity(0.34),
        cardBackground: Color.white.opacity(0.055),
        cardBorder: Color.white.opacity(0.14),
        controlBackground: Color.white.opacity(0.055),
        controlHoverBackground: Color.white.opacity(0.14),
        primaryControlBackground: Color.white,
        primaryControlForeground: Color.black,
        progressFill: Color.white.opacity(0.90),
        iconTileBackground: Color.white.opacity(0.075)
    )

    init(track: SpotifyTrack?) {
        guard let artwork = track?.artwork,
              let palette = Self.palette(from: artwork) else {
            self = Self.fallback
            return
        }

        self = Self(primary: palette.primary, secondary: palette.secondary)
    }

    private init(primary: NSColor, secondary: NSColor) {
        surfaceTop = Color.white.opacity(0.13)
        surfaceMiddle = Self.color(Self.adjusted(primary, saturation: 0.62, brightness: 1.08, alpha: 0.07))
        surfaceBottom = Color.black.opacity(0.36)
        cardBackground = Color.white.opacity(0.06)
        cardBorder = Self.color(Self.adjusted(secondary, saturation: 0.52, brightness: 1.18, alpha: 0.13))
        controlBackground = Color.white.opacity(0.055)
        controlHoverBackground = Self.color(Self.adjusted(primary, saturation: 0.44, brightness: 1.15, alpha: 0.10))
        primaryControlBackground = Color.white
        primaryControlForeground = Color.black
        progressFill = Color.white.opacity(0.92)
        iconTileBackground = Color.white.opacity(0.075)
    }

    private init(
        surfaceTop: Color,
        surfaceMiddle: Color,
        surfaceBottom: Color,
        cardBackground: Color,
        cardBorder: Color,
        controlBackground: Color,
        controlHoverBackground: Color,
        primaryControlBackground: Color,
        primaryControlForeground: Color,
        progressFill: Color,
        iconTileBackground: Color
    ) {
        self.surfaceTop = surfaceTop
        self.surfaceMiddle = surfaceMiddle
        self.surfaceBottom = surfaceBottom
        self.cardBackground = cardBackground
        self.cardBorder = cardBorder
        self.controlBackground = controlBackground
        self.controlHoverBackground = controlHoverBackground
        self.primaryControlBackground = primaryControlBackground
        self.primaryControlForeground = primaryControlForeground
        self.progressFill = progressFill
        self.iconTileBackground = iconTileBackground
    }
}

private extension SpotifyTheme {
    struct Candidate {
        let color: NSColor
        let hue: CGFloat
        let saturation: CGFloat
        let brightness: CGFloat

        var score: CGFloat {
            saturation * 1.5 + min(brightness, 0.78) * 0.42
        }
    }

    static func palette(from image: NSImage) -> (primary: NSColor, secondary: NSColor)? {
        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else {
            return nil
        }

        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        guard width > 0, height > 0 else { return nil }

        let step = max(1, min(width, height) / 24)
        var candidates: [Candidate] = []

        for y in stride(from: step / 2, to: height, by: step) {
            for x in stride(from: step / 2, to: width, by: step) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                      let candidate = candidate(from: color) else {
                    continue
                }

                candidates.append(candidate)
            }
        }

        guard let primary = candidates.max(by: { $0.score < $1.score }) else {
            return nil
        }

        let secondary = candidates
            .filter { candidate in
                hueDistance(primary.hue, candidate.hue) > 0.08
                    || abs(primary.brightness - candidate.brightness) > 0.20
            }
            .max(by: { $0.score < $1.score })?
            .color
            ?? adjusted(primary.color, saturation: 0.82, brightness: 0.56, alpha: 1)

        return (primary.color, secondary)
    }

    static func candidate(from color: NSColor) -> Candidate? {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        guard alpha > 0.75,
              brightness > 0.10,
              brightness < 0.96 else {
            return nil
        }

        let minimumSaturation: CGFloat = brightness > 0.86 ? 0.20 : 0.10
        guard saturation >= minimumSaturation else { return nil }

        return Candidate(color: color, hue: hue, saturation: saturation, brightness: brightness)
    }

    static func adjusted(
        _ color: NSColor,
        saturation saturationMultiplier: CGFloat,
        brightness brightnessMultiplier: CGFloat,
        alpha: CGFloat
    ) -> NSColor {
        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var currentAlpha: CGFloat = 0

        rgb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &currentAlpha)

        return NSColor(
            calibratedHue: hue,
            saturation: min(max(saturation * saturationMultiplier, 0), 1),
            brightness: min(max(brightness * brightnessMultiplier, 0), 1),
            alpha: alpha
        )
    }

    static func color(_ color: NSColor) -> Color {
        Color(nsColor: color)
    }

    static func hueDistance(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
        let distance = abs(lhs - rhs)
        return min(distance, 1 - distance)
    }
}
