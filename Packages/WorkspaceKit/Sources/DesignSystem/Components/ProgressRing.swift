import SwiftUI

/// A small circular progress indicator for checklist completion.
public struct ProgressRing: View {
    private let progress: Double
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var lineWidth: CGFloat = 4

    public init(progress: Double) {
        self.progress = min(max(progress, 0), 1)
    }

    public var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.35), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}
