import ActivityKit
import WidgetKit
import SwiftUI

public struct PomodoroLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // ── Lock Screen / Banner View ──
            PomodoroLockScreenBannerView(context: context)
                .activityBackgroundTint(Color(red: 0x16/255.0, green: 0x16/255.0, blue: 0x16/255.0))
        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded Dynamic Island (Long Press) ──
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(phaseAccentColor(for: context.state.phase))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(phaseTitle(for: context.state.phase, session: context.state.currentSession, total: context.state.totalSessions))
                                .font(.system(size: 13, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.white)

                            Text(phaseMessage(for: context.state.phase))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.55))
                        }
                    }
                    .padding(.leading, 6)
                    .padding(.top, 6)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    // Right Side: Clean Live Countdown Timer
                    VStack(alignment: .trailing, spacing: 2) {
                        if context.state.isRunning {
                            Text(timerInterval: context.state.startDate...context.state.targetEndTime, countsDown: true)
                                .font(.system(size: 26, weight: .light, design: .default))
                                .monospacedDigit()
                                .foregroundStyle(Color.white)
                        } else {
                            Text(formatPausedTime(seconds: context.state.timeRemainingWhenPaused))
                                .font(.system(size: 26, weight: .light, design: .default))
                                .monospacedDigit()
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.trailing, 6)
                    .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Bottom: 4 Session Dots + Milestone Subtitle
                    HStack {
                        HStack(spacing: 7) {
                            ForEach(1...context.state.totalSessions, id: \.self) { session in
                                let isCurrent = session == context.state.currentSession
                                let isDone = session < context.state.currentSession

                                Circle()
                                    .fill(isDone ? Color.white.opacity(0.9) : (isCurrent ? phaseAccentColor(for: context.state.phase) : Color.white.opacity(0.2)))
                                    .frame(width: isCurrent ? 7 : 5, height: isCurrent ? 7 : 5)
                            }
                        }

                        Spacer()

                        Text("Milestone Focus")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                // ── Compact Leading: Exactly like Apple Clock App (Hourglass Icon) ──
                Image(systemName: "hourglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(phaseAccentColor(for: context.state.phase))
            } compactTrailing: {
                // ── Compact Trailing: Exactly like Apple Clock App (Live Native Timer) ──
                if context.state.isRunning {
                    Text(timerInterval: context.state.startDate...context.state.targetEndTime, countsDown: true)
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, alignment: .trailing)
                } else {
                    Text(formatPausedTime(seconds: context.state.timeRemainingWhenPaused))
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .frame(width: 44, alignment: .trailing)
                }
            } minimal: {
                // ── Minimal Single Bubble ──
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
            // Left: Hourglass Icon + Session Info
            HStack(spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(phaseAccentColor(for: context.state.phase))

                VStack(alignment: .leading, spacing: 3) {
                    Text(phaseTitle(for: context.state.phase, session: context.state.currentSession, total: context.state.totalSessions))
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.white)

                    Text(phaseMessage(for: context.state.phase))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }

            Spacer()

            // Right: Timer + Session Dots
            VStack(alignment: .trailing, spacing: 6) {
                if context.state.isRunning {
                    Text(timerInterval: context.state.startDate...context.state.targetEndTime, countsDown: true)
                        .font(.system(size: 30, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(Color.white)
                } else {
                    Text(formatPausedTime(seconds: context.state.timeRemainingWhenPaused))
                        .font(.system(size: 30, weight: .light))
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
        return Color(red: 0x4E/255.0, green: 0xC3/255.0, blue: 0x89/255.0)
    case "longBreak":
        return Color(red: 0x5A/255.0, green: 0xC8/255.0, blue: 0xFA/255.0)
    default:
        return Color.white
    }
}

private func formatPausedTime(seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}
