import SwiftUI

public struct SplashView: View {
    public let onComplete: () -> Void
    @Environment(\.theme) private var theme

    // 5 vertical dots in a single middle line
    private let totalDots: Int = 5

    // State for bottom-to-top progressive ignition
    // Index 4 is bottom, Index 0 is top
    @State private var illuminatedCount: Int = 0
    @State private var topDotGlow: Bool = false
    @State private var topDotScale: CGFloat = 1.0
    @State private var containerOpacity: Double = 1.0

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Obsidian Backdrop matching #0C0C0E
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                // Vertical column of dots in the exact middle
                VStack(spacing: 14) {
                    ForEach(0..<totalDots, id: \.self) { index in
                        // index 0 is top, index 4 is bottom
                        let isTop = (index == 0)
                        let isIlluminated = isDotIlluminated(index: index)

                        ZStack {
                            if isTop && topDotGlow {
                                // Subtle ambient glow around top dot
                                Circle()
                                    .fill(Color.white.opacity(0.35))
                                    .frame(width: 18, height: 18)
                                    .blur(radius: 6)

                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 12, height: 12)
                            }

                            Circle()
                                .fill(dotColor(isTop: isTop, isIlluminated: isIlluminated))
                                .frame(
                                    width: isTop ? (8.0 * topDotScale) : 6.5,
                                    height: isTop ? (8.0 * topDotScale) : 6.5
                                )
                        }
                        .frame(width: 20, height: 20)
                    }
                }

                Spacer()
            }
            .opacity(containerOpacity)
        }
        .onAppear {
            startRisingDotSequence()
        }
    }

    /// Determines if a dot has been illuminated by the rising wave.
    /// Bottom dot is index 4 (1st to light up), index 0 is top dot (5th to light up).
    private func isDotIlluminated(index: Int) -> Bool {
        let stepFromBottom = (totalDots - 1) - index
        return illuminatedCount > stepFromBottom
    }

    private func dotColor(isTop: Bool, isIlluminated: Bool) -> Color {
        if isIlluminated {
            return Color.white
        } else {
            // Faded dot baseline, matching the app's widget faded dot styling
            return Color.white.opacity(0.18)
        }
    }

    private func startRisingDotSequence() {
        // Step-by-step rising wave: bottom to top
        let stepDelay = 0.12 // 120ms per dot rise

        for step in 1...totalDots {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDelay) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    illuminatedCount = step
                }

                // When the wave reaches the top dot (step == 5)
                if step == totalDots {
                    HapticsManager.shared.impact(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        topDotGlow = true
                        topDotScale = 1.25
                    }
                }
            }
        }

        // Smooth dissolve into the app
        let holdDelay = 1.05
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDelay) {
            withAnimation(.easeInOut(duration: 0.28)) {
                containerOpacity = 0.0
            }
        }

        // Dismiss splash and reveal the main interface
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDelay + 0.3) {
            onComplete()
        }
    }
}

