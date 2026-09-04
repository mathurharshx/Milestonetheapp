import SwiftUI
import Charts

public struct VelocityReportSheet: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall: Bool = false
    @State private var shareSummaryText: String = ""

    public init() {}

    private var currentMission: Mission? {
        missionStore.currentPillarMission
    }

    private var report: VelocityReport {
        guard let mission = currentMission else {
            return VelocityCalculator.calculateReport(
                mission: Mission(title: "Active Sprint", targetDate: Date().addingTimeInterval(86400 * 7))
            )
        }
        return VelocityCalculator.calculateReport(
            mission: mission,
            archivedMissions: missionStore.archivedMissions
        )
    }

    private var isLocked: Bool {
        // Gate for free users
        !subscriptionStore.isProUser
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            // Subtle Background Radial Glow
            VStack {
                Circle()
                    .fill(report.status.tintColor.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 60)
                    .offset(y: -60)
                Spacer()
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // ── Top Navigation Bar ──
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(report.status.tintColor)

                        Text("PACING REPORT")
                            .font(.system(size: 11, weight: .black))
                            .tracking(3)
                            .foregroundStyle(report.status.tintColor)
                    }

                    Spacer()

                    Button {
                        HapticsManager.shared.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(theme.textTertiary.opacity(0.7))
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 12)

                // ── Scrollable Report Content ──
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // ── 1. Hero Velocity Number & Status ──
                        VStack(spacing: 8) {
                            Text(currentMission?.title.uppercased() ?? "CURRENT SPRINT")
                                .font(.system(size: 11, weight: .black))
                                .tracking(2)
                                .foregroundStyle(theme.textTertiary)
                                .lineLimit(1)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(report.formattedVelocity)
                                    .font(.system(size: 58, weight: .black, design: .monospaced))
                                    .tracking(-2)
                                    .foregroundStyle(theme.textPrimary)

                                Text("VELOCITY")
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(2)
                                    .foregroundStyle(report.status.tintColor)
                            }

                            // Status Chip
                            HStack(spacing: 6) {
                                Image(systemName: report.status.badgeSymbol)
                                    .font(.system(size: 11, weight: .bold))

                                Text(report.status.title)
                                    .font(.system(size: 11, weight: .heavy))
                                    .tracking(1.5)
                            }
                            .foregroundStyle(report.status.tintColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(report.status.tintColor.opacity(0.15))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(report.status.tintColor.opacity(0.4), lineWidth: 1)
                            )

                            Text(report.status.subtitle)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.top, 2)
                        }
                        .padding(.vertical, 8)

                        // ── 2. Primary 2x2 Bento Metrics ──
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // Bento 1: Timeline Drift Forecast
                                metricCard(
                                    title: "TIMELINE DRIFT",
                                    icon: "clock.arrow.2.circlepath",
                                    iconColor: report.status.tintColor,
                                    mainValue: report.formattedDriftText,
                                    subtitle: "Projected: \(formattedDate(report.projectedCompletionDate))"
                                )

                                // Bento 2: Sprint Streak
                                metricCard(
                                    title: "STREAK CADENCE",
                                    icon: "flame.fill",
                                    iconColor: Color(red: 0.95, green: 0.55, blue: 0.25),
                                    mainValue: "\(report.streakCount) Sprints",
                                    subtitle: "Consecutive on-time delivery"
                                )
                            }

                            HStack(spacing: 12) {
                                // Bento 3: Task Execution
                                metricCard(
                                    title: "TASKS COMPLETED",
                                    icon: "checklist.checked",
                                    iconColor: theme.accent,
                                    mainValue: "\(report.completedTasksCount) / \(report.totalTasksCount)",
                                    subtitle: "\(Int(report.taskProgressRatio * 100))% of milestone scope"
                                )

                                // Bento 4: Time Elapsed
                                metricCard(
                                    title: "TIME ELAPSED",
                                    icon: "hourglass.bottomhalf.filled",
                                    iconColor: theme.textSecondary,
                                    mainValue: "\(Int(report.timeElapsedRatio * 100))%",
                                    subtitle: "Duration consumed"
                                )
                            }
                        }

                        // ── 3. Weekly Focus Cadence Chart ──
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("7-DAY FOCUS CADENCE")
                                        .font(.system(size: 10, weight: .black))
                                        .tracking(1.5)
                                        .foregroundStyle(theme.textTertiary)

                                    Text("Pomodoro Focus Minutes")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(theme.textPrimary)
                                }

                                Spacer()

                                let totalMins = report.weeklyCadence.reduce(0) { $0 + $1.minutes }
                                Text("\(totalMins)m total")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(theme.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(theme.accent.opacity(0.12)))
                            }

                            // Swift Chart
                            Chart {
                                ForEach(report.weeklyCadence) { cadence in
                                    BarMark(
                                        x: .value("Day", cadence.dayLabel),
                                        y: .value("Minutes", cadence.minutes)
                                    )
                                    .foregroundStyle(
                                        cadence.isToday
                                            ? LinearGradient(
                                                colors: [report.status.tintColor, report.status.tintColor.opacity(0.6)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            : LinearGradient(
                                                colors: [theme.textTertiary.opacity(0.5), theme.textTertiary.opacity(0.2)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                    )
                                    .cornerRadius(4)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { _ in
                                    AxisGridLine().foregroundStyle(theme.border.opacity(0.2))
                                    AxisValueLabel().foregroundStyle(theme.textTertiary).font(.system(size: 9))
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel().foregroundStyle(theme.textSecondary).font(.system(size: 10, weight: .bold))
                                }
                            }
                            .frame(height: 140)
                            .padding(.vertical, 4)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(theme.surface.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(theme.border.opacity(0.35), lineWidth: 1)
                        )

                        // ── 4. Share / Export Action Button ──
                        ShareLink(
                            item: generateShareSummary(),
                            subject: Text("Milestone Sprint Report: \(currentMission?.title ?? "Mission")"),
                            message: Text("Tracking with Milestone.")
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 13, weight: .bold))

                                Text("EXPORT PACING BRIEF")
                                    .font(.system(size: 12, weight: .black))
                                    .tracking(2)
                            }
                            .foregroundStyle(theme.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(theme.accent)
                            )
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // ── Bento Metric Card Helper ──
    @ViewBuilder
    private func metricCard(
        title: String,
        icon: String,
        iconColor: Color,
        mainValue: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .tracking(1)
                    .foregroundStyle(theme.textTertiary)
            }

            Text(mainValue)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.border.opacity(0.3), lineWidth: 1)
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, h:mm a"
        return formatter.string(from: date)
    }

    private func generateShareSummary() -> String {
        let title = currentMission?.title ?? "Milestone Sprint"
        return """
        🎯 MILESTONE SPRINT REPORT
        Mission: "\(title)"
        ⚡︎ Pacing Velocity: \(report.formattedVelocity) (\(report.status.title))
        ⏳ Timeline Drift: \(report.formattedDriftText)
        📋 Scope: \(report.completedTasksCount)/\(report.totalTasksCount) tasks done (\(Int(report.taskProgressRatio * 100))%)
        🔥 Streak: \(report.streakCount) on-time sprint deliveries
        Projected Delivery: \(formattedDate(report.projectedCompletionDate))

        Shared via Milestone.
        """
    }
}
