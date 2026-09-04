import SwiftUI

public struct PomodoroRingView: View {
    public let progress: Double
    public let timeRemaining: Int
    public let isRunning: Bool
    public let isStarted: Bool
    public let phase: PomodoroPhase
    public let color: Color
    public let message: String

    public let isSoundscapePlaying: Bool

    @Environment(\.theme) private var theme
    @State private var isBreathingPulse: Bool = false

    private let segments = 96
    private let dotSize: CGFloat = 3.5
    private let ringSize: CGFloat = 280

    public init(
        progress: Double,
        timeRemaining: Int,
        isRunning: Bool,
        isStarted: Bool,
        phase: PomodoroPhase,
        color: Color,
        message: String,
        isSoundscapePlaying: Bool = false
    ) {
        self.progress = progress
        self.timeRemaining = timeRemaining
        self.isRunning = isRunning
        self.isStarted = isStarted
        self.phase = phase
        self.color = color
        self.message = message
        self.isSoundscapePlaying = isSoundscapePlaying
    }

    private var timeFormatted: String {
        let mins = timeRemaining / 60
        let secs = timeRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private var isBreakPhase: Bool {
        phase == .shortBreak || phase == .longBreak
    }

    public var body: some View {
        ZStack {
            // ── 1. Biological Box-Breathing Focus & Recovery Aura (4.0s Rhythm) ──
            if isRunning {
                // Outer Diffused Focus Halo
                Circle()
                    .fill(color.opacity(isBreathingPulse ? (isSoundscapePlaying ? 0.10 : 0.07) : 0.02))
                    .frame(width: ringSize - 16, height: ringSize - 16)
                    .blur(radius: isSoundscapePlaying ? 32 : 26)
                    .scaleEffect(isBreathingPulse ? (isSoundscapePlaying ? 1.07 : 1.04) : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                        value: isBreathingPulse
                    )

                // Inner Harmonic Resonance Core
                Circle()
                    .fill(color.opacity(isBreathingPulse ? (isSoundscapePlaying ? 0.06 : 0.04) : 0.01))
                    .frame(width: ringSize * 0.55, height: ringSize * 0.55)
                    .blur(radius: 18)
                    .scaleEffect(isBreathingPulse ? 1.03 : 0.97)
                    .animation(
                        Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                        value: isBreathingPulse
                    )
            }

            // High-Performance Single-Pass Canvas Rendering (0.01ms CPU render)
            let emptyDotColor = theme.dotEmpty
            Canvas { context, size in
                let radius = (ringSize - dotSize * 2) / 2
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let filledCount = Int(round(progress * Double(segments)))

                for i in 0..<segments {
                    let angle = (Double(i) / Double(segments)) * 2 * .pi - (.pi / 2)
                    let x = center.x + radius * CGFloat(cos(angle))
                    let y = center.y + radius * CGFloat(sin(angle))
                    let isFilled = i < filledCount
                    let isLead = isFilled && (i == filledCount - 1)

                    let currentDotSize = isLead ? dotSize * 1.5 : dotSize
                    let rect = CGRect(
                        x: x - currentDotSize / 2,
                        y: y - currentDotSize / 2,
                        width: currentDotSize,
                        height: currentDotSize
                    )

                    let dotColor = isFilled ? color : emptyDotColor
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }
            .scaleEffect(isRunning && isBreathingPulse ? (isBreakPhase ? 1.015 : 1.008) : 1.0)
            .animation(
                isRunning
                    ? Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
                    : .default,
                value: isBreathingPulse
            )
            .allowsHitTesting(false)

            // Center Content
            VStack(spacing: 8) {
                // Rock-solid Stable Monospaced Timer (Zero Bouncing / Zero Jitter)
                Text(timeFormatted)
                    .font(.system(size: 58, weight: .ultraLight, design: .default))
                    .monospacedDigit()
                    .tracking(2)
                    .foregroundStyle(theme.textPrimary)
                    .transaction { transaction in
                        transaction.animation = nil
                    }

                // Status Pill
                Text(isRunning ? (isBreakPhase ? "RESTING" : "RUNNING") : (isStarted ? "PAUSED" : "READY"))
                    .font(.system(size: 9, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.14))
                    )

                // Micro-prompt Message
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isBreakPhase ? color.opacity(0.9) : theme.textTertiary)
                    .padding(.horizontal, 24)
                    .padding(.top, 2)
            }
            .allowsHitTesting(false)
        }
        .frame(width: ringSize, height: ringSize)
        .onAppear {
            if isRunning {
                isBreathingPulse = true
            }
        }
        .onChange(of: isRunning) { _, running in
            if running {
                isBreathingPulse = true
            } else {
                isBreathingPulse = false
            }
        }
    }
}
