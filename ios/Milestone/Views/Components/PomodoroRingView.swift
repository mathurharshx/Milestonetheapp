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

    public var body: some View {
        ZStack {
            // 96-Dot Circular Progress Ring
            let radius = (ringSize - dotSize * 2) / 2
            let filledCount = Int(round(progress * Double(segments)))

            ForEach(0..<segments, id: \.self) { i in
                let angle = (Double(i) / Double(segments)) * 2 * .pi - (.pi / 2)
                let x = radius * CGFloat(cos(angle))
                let y = radius * CGFloat(sin(angle))
                let isFilled = i < filledCount
                let isLead = isFilled && (i == filledCount - 1)

                Circle()
                    .fill(isFilled ? color : theme.dotEmpty)
                    .frame(width: isLead ? dotSize * 1.5 : dotSize, height: isLead ? dotSize * 1.5 : dotSize)
                    .shadow(
                        color: isLead ? color.opacity(0.8) : .clear,
                        radius: isLead ? 6 : 0
                    )
                    .offset(x: x, y: y)
            }
            .allowsHitTesting(false)

            // Center Content
            VStack(spacing: 8) {
                // Rock-solid Stable Monospaced Timer (Zero Bouncing / Zero Jitter)
                Text(timeFormatted)
                    .font(.system(size: 58, weight: .ultraLight, design: .default))
                    .monospacedDigit()
                    .tracking(2)
                    .foregroundStyle(theme.textPrimary)
                    .animation(nil, value: timeRemaining)
                    .transaction { transaction in
                        transaction.animation = nil
                    }

                // Status Pill
                Text(isRunning ? "RUNNING" : (isStarted ? "PAUSED" : "READY"))
                    .font(.system(size: 9, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.12))
                    )

                // Message
                Text(message)
                    .font(.system(size: 12, weight: .regular))
                    .tracking(0.5)
                    .foregroundStyle(theme.textTertiary)
                    .padding(.top, 2)
            }
            .allowsHitTesting(false)
        }
        .frame(width: ringSize, height: ringSize)
    }
}
