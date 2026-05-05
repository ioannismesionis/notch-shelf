import SwiftUI

struct SpotifyLogoView: View {
    var size: CGFloat
    var showBackground = true

    var body: some View {
        ZStack {
            if showBackground {
                Circle()
                    .fill(Color(red: 0.12, green: 0.73, blue: 0.33))
            }

            SpotifyWave(index: 0)
                .stroke(
                    Color.black.opacity(0.82),
                    style: StrokeStyle(lineWidth: size * 0.068, lineCap: .round)
                )

            SpotifyWave(index: 1)
                .stroke(
                    Color.black.opacity(0.82),
                    style: StrokeStyle(lineWidth: size * 0.058, lineCap: .round)
                )

            SpotifyWave(index: 2)
                .stroke(
                    Color.black.opacity(0.82),
                    style: StrokeStyle(lineWidth: size * 0.048, lineCap: .round)
                )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct SpotifyWave: Shape {
    let index: Int

    func path(in rect: CGRect) -> Path {
        let points = controlPoints(in: rect)
        var path = Path()

        path.move(to: points.start)
        path.addCurve(to: points.end, control1: points.control1, control2: points.control2)

        return path
    }

    private func controlPoints(in rect: CGRect) -> (
        start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        end: CGPoint
    ) {
        switch index {
        case 0:
            return (
                CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.39),
                CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.31),
                CGPoint(x: rect.minX + rect.width * 0.62, y: rect.minY + rect.height * 0.34),
                CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.42)
            )
        case 1:
            return (
                CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.52),
                CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.47),
                CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY + rect.height * 0.49),
                CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.55)
            )
        default:
            return (
                CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.64),
                CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.60),
                CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY + rect.height * 0.61),
                CGPoint(x: rect.minX + rect.width * 0.64, y: rect.minY + rect.height * 0.65)
            )
        }
    }
}
