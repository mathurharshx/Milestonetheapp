import SwiftUI

public struct CountdownTimerView: View {
    public let countdown: CountdownData
    @Environment(\.theme) private var theme

    public init(countdown: CountdownData) {
        self.countdown = countdown
    }

    public var body: some View {
        VStack(spacing: 4) {
            // Days Hero Display - Precision Kinetic Mechanical Number Drum
            Text("\(countdown.days)")
                .font(.system(size: 72, weight: .ultraLight, design: .default))
                .monospacedDigit()
                .tracking(-2)
                .foregroundStyle(theme.textPrimary)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy(duration: 0.38, extraBounce: 0), value: countdown.days)

            Text("DAYS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(6)
                .foregroundStyle(theme.textTertiary)
                .padding(.bottom, 8)

            // HMS Row - Precision Kinetic Split-Flap Digit Drums
            HStack(spacing: 8) {
                TimeUnitView(value: countdown.hours, label: "HR")
                Text(":")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(theme.textMuted)
                    .offset(y: -8)
                TimeUnitView(value: countdown.minutes, label: "MIN")
                Text(":")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(theme.textMuted)
                    .offset(y: -8)
                TimeUnitView(value: countdown.seconds, label: "SEC")
            }
        }
        .padding(.vertical, 16)
    }
}

private struct TimeUnitView: View {
    let value: Int
    let label: String
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 17, weight: .regular))
                .monospacedDigit()
                .tracking(1)
                .foregroundStyle(theme.textTertiary)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy(duration: 0.35, extraBounce: 0), value: value)

            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(2)
                .foregroundStyle(theme.textMuted)
        }
        .frame(minWidth: 40)
    }
}
