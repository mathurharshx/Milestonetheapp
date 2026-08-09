import ActivityKit
import WidgetKit
import SwiftUI

public struct PomodoroLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // ── Lock Screen / Banner View ──
            PomodoroLockScreenBannerView(context: context)
                .activityBackgroundTint(Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0))
        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded Dynamic Island (Long Press) ──
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(phaseAccentColor(for: context.state.phase))

                        Text(phaseTitle(for: context.state.phase, session: context.state.currentSession, total: context.state.totalSessions))
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(phaseAccentColor(for: context.state.phase))
                    }
                    .padding(.leading, 4)
                    .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isRunning ? "RUNNING" : "PAUSED")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(context.state.isRunning ? phaseAccentColor(for: context.state.phase) : Color.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(phaseAccentColor(for: context.state.phase).opacity(0.15))
                        )
                        .padding(.trailing, 4)
                        .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        // Big Hero Countdown Timer
                        if context.state.isRunning {
                            Text(timerInterval: Date.now...context.state.targetEndTime, countsDown: true)
                                .font(.system(size: 38, weight: .light, design: .default))
                                .monospacedDigit()
                                .tracking(1)
                                .foregroundStyle(Color.white)
                        } else {
                            Text(formatPausedTime(seconds: context.state.timeRemainingWhenPaused))
                                .font(.system(size: 38, weight: .light, design: .default))
                                .monospacedDigit()
                                .tracking(1)
                                .foregroundStyle(Color.white)
                        }

                        // 4 Session Dots Row
                        HStack(spacing: 8) {
                            ForEach(1...context.state.totalSessions, id: \.self) { session in
                                let isCurrent = session == context.state.currentSession
                                let isDone = session < context.state.currentSession

                                Circle()
                                    .fill(isDone ? Color.white.opacity(0.85) : (isCurrent ? phaseAccentColor(for: context.state.phase) : Color.white.opacity(0.18)))
                                    .frame(width: isCurrent ? 7 : 5, height: isCurrent ? 7 : 5)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(phaseMessage(for: context.state.phase))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))

                        Spacer()

                        Text("Milestone Focus")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                // ── Compact Leading (Left Pill) ──
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(phaseAccentColor(for: context.state.phase))

                    Text("\(context.state.currentSession)/\(context.state.totalSessions)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .padding(.leading, 2)
            } compactTrailing: {
                // ── Compact Trailing (Right Pill) ──
                if context.state.isRunning {
                    Text(timerInterval: Date.now...context.state.targetEndTime, countsDown: true)
                        .font(.system(size: 12, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(phaseAccentColor(for: context.state.phase))
                        .frame(minWidth: 44, alignment: .trailing)
                } else {
                    Text(formatPausedTime(seconds: context.state.timeRemainingWhenPaused))
                        .font(.system(size: 12, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.gray)
                        .frame(minWidth: 44, alignment: .trailing)
                }
            } minimal: {
                // ── Minimal (When 2 activities are active) ──
                Image(systemName: "hourglass")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(phaseAccentColor(for: context.state.phase))
            }
        }
    }
}

// ── Lock Screen Banner View ──
private struct PomodoroLockScreenBannerView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Left: Icon + Session Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(phaseAccentColor(for: context.state.phase))

                    Text("MILESTONE FOCUS")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(2.5)
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                Text(phaseTitle(for: context.state.phase, session: context.state.currentSession, total: context.state.totalSessions))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)

                Text(phaseMessage(for: context.state.phase))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            Spacer()

            // Right: Timer + Session Dots
            VStack(alignment: .trailing, spacing: 6) {
                if context.state.isRunning {
                    Text(timerInterval: Date.now...context.state.targetEndTime, countsDown: true)
                        .font(.system(size: 32, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(Color.white)
                } else {
                    Text(formatPausedTime(seconds: context.state.timeRemainingWhenPaused))
                        .font(.system(size: 32, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(Color.white)
                }

                HStack(spacing: 6) {
                    ForEach(1...context.state.totalSessions, id: \.self) { session in
                        let isCurrent = session == context.state.currentSession
                        let isDone = session < context.state.currentSession

                        Circle()
                            .fill(isDone ? Color.white.opacity(0.85) : (isCurrent ? phaseAccentColor(for: context.state.phase) : Color.white.opacity(0.2)))
                            .frame(width: isCurrent ? 6 : 4.5, height: isCurrent ? 6 : 4.5)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// ── Helpers ──
private func phaseTitle(for phase: String, session: Int, total: Int) -> String {
    switch phase {
    case "focus":
        return "FOCUS \(session)/\(total)"
    case "shortBreak":
        return "SHORT BREAK"
    case "longBreak":
        return "LONG BREAK"
    default:
        return "FOCUS"
    }
}

private func phaseMessage(for phase: String) -> String {
    switch phase {
    case "focus":
        return "Stay locked in."
    case "shortBreak":
        return "Rest your mind."
    case "longBreak":
        return "Great work. Recharge."
    default:
        return "Focus time."
    }
}

private func phaseAccentColor(for phase: String) -> Color {
    switch phase {
    case "focus":
        return Color.white
    case "shortBreak":
        return Color(red: 0x4E/255.0, green: 0xC3/255.0, blue: 0x89/255.0) // Mint/Green
    case "longBreak":
        return Color(red: 0x5A/255.0, green: 0xC8/255.0, blue: 0xFA/255.0) // Sky Blue
    default:
        return Color.white
    }
}

private func formatPausedTime(seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}
