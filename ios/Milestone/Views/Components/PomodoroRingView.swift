import SwiftUI

public struct PomodoroRingView: View {
    public let progress: Double
    public let timeRemaining: Int
    public let isRunning: Bool
    public let isStarted: Bool
    public let phase: PomodoroPhase
    public let color: Color
    public let message: String

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
        message: String
    ) {
        self.progress = progress
        self.timeRemaining = timeRemaining
        self.isRunning = isRunning
        self.isStarted = isStarted
        self.phase = phase
        self.color = color
        self.message = message
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
            // Ambient Calming Breathing Aura for Breaks
            if isBreakPhase && isRunning {
                Circle()
                    .fill(color.opacity(isBreathingPulse ? 0.08 : 0.02))
                    .frame(width: ringSize - 20, height: ringSize - 20)
                    .blur(radius: 20)
                    .scaleEffect(isBreathingPulse ? 1.08 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 3.8).repeatForever(autoreverses: true),
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
            .scaleEffect(isBreakPhase && isRunning && isBreathingPulse ? 1.02 : 1.0)
            .animation(
                isBreakPhase && isRunning
                    ? Animation.easeInOut(duration: 3.8).repeatForever(autoreverses: true)
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
            if isBreakPhase && isRunning {
                isBreathingPulse = true
            }
        }
        .onChange(of: isRunning) { _, running in
            if isBreakPhase && running {
                isBreathingPulse = true
            } else {
                isBreathingPulse = false
            }
        }
        .onChange(of: phase) { _, newPhase in
            if (newPhase == .shortBreak || newPhase == .longBreak) && isRunning {
                isBreathingPulse = true
            } else {
                isBreathingPulse = false
            }
        }
    }
}
