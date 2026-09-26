import WidgetKit
import SwiftUI

struct MissionProvider: TimelineProvider {
    func placeholder(in context: Context) -> MissionEntry {
        MissionEntry(date: Date(), data: MilestoneWidgetData())
    }

    func getSnapshot(in context: Context, completion: @escaping (MissionEntry) -> Void) {
        let data = SharedWidgetStore.load() ?? MilestoneWidgetData()
        completion(MissionEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MissionEntry>) -> Void) {
        let data = SharedWidgetStore.load() ?? MilestoneWidgetData()
        let schedule = WidgetDateCalculations.generateMidnightSchedule(from: Date(), daysAhead: 4)
        let entries = schedule.map { MissionEntry(date: $0, data: data) }
        let nextUpdate = schedule.last ?? Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }
}

struct MissionEntry: TimelineEntry {
    let date: Date
    let data: MilestoneWidgetData
}

struct MilestoneMissionWidgetView: View {
    let entry: MissionEntry
    @Environment(\.widgetFamily) var family

    private var daysRemaining: Int {
        guard let target = entry.data.missionTargetDate else { return 0 }
        let targetDate = Date(timeIntervalSince1970: target)
        return WidgetDateCalculations.daysRemaining(targetDate: targetDate, asOf: entry.date)
    }

    private var totalDays: Int {
        guard let created = entry.data.missionCreatedAt,
              let target = entry.data.missionTargetDate else { return 1 }
        let createdDate = Date(timeIntervalSince1970: created)
        let targetDate = Date(timeIntervalSince1970: target)
        return WidgetDateCalculations.totalDays(createdAt: createdDate, targetDate: targetDate)
    }

    private var progressRatio: Double {
        guard let created = entry.data.missionCreatedAt else { return 0 }
        let createdDate = Date(timeIntervalSince1970: created)
        let elapsed = WidgetDateCalculations.daysElapsed(createdAt: createdDate, asOf: entry.date)
        return min(1.0, max(0.0, Double(elapsed) / Double(totalDays)))
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .accessoryCircular:
                accessoryCircularView
            case .accessoryInline:
                accessoryInlineView
            default:
                smallView
            }
        }
        .widgetURL(URL(string: "milestone://mission"))
    }

    // ── Small Widget ──
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.data.activeGlowColor)
                        .frame(width: 5, height: 5)
                    Text(entry.data.missionCategory == "personal" ? "PERSONAL" : "MISSION")
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(2.0)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }

                Spacer()

                if entry.data.missionTodosTotal > 0 {
                    Text("\(entry.data.missionTodosDone)/\(entry.data.missionTodosTotal)")
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundStyle(entry.data.activeGlowColor)
                }
            }

            Spacer()

            // Large Digits
            Text("\(daysRemaining)")
                .font(.system(size: 42, weight: .bold))
                .tracking(-1)
                .foregroundStyle(entry.data.textPrimaryColor)

            Text("DAYS REMAINING")
                .font(.system(size: 8.5, weight: .heavy))
                .tracking(1.5)
                .foregroundStyle(entry.data.textSecondaryColor)
                .padding(.bottom, 8)

            Spacer()

            // Mission Title
            Text(entry.data.missionTitle ?? "Active Mission")
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
                .foregroundStyle(entry.data.textPrimaryColor)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Medium Widget ──
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left Column: Mission Countdown
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.data.activeGlowColor)
                        .frame(width: 5, height: 5)

                    Text(entry.data.missionCategory == "personal" ? "PERSONAL" : "KEYSTONE")
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(2.2)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }

                Text("\(daysRemaining)")
                    .font(.system(size: 38, weight: .bold))
                    .tracking(-1)
                    .foregroundStyle(entry.data.textPrimaryColor)

                Text("DAYS REMAINING")
                    .font(.system(size: 8.5, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(entry.data.textSecondaryColor)

                Spacer()

                Text(entry.data.missionTitle ?? "No active mission")
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(entry.data.textPrimaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right Column: Priority Task & Progress Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("PRIORITY TASK")
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(1.5)
                        .foregroundStyle(entry.data.textSecondaryColor)

                    Spacer()

                    if entry.data.missionTodosTotal > 0 {
                        Text("\(entry.data.missionTodosDone)/\(entry.data.missionTodosTotal)")
                            .font(.system(size: 9.5, weight: .heavy))
                            .foregroundStyle(entry.data.activeGlowColor)
                    }
                }

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "circle")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(entry.data.activeGlowColor)
                        .padding(.top, 2)

                    Text(entry.data.topPendingTaskText ?? (entry.data.missionTodosTotal > 0 ? "All tasks completed" : "No pending tasks"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(entry.data.textPrimaryColor)
                        .lineLimit(2)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(entry.data.trackColor)
                            .frame(height: 4)

                        Capsule()
                            .fill(entry.data.accentColor)
                            .frame(width: geo.size.width * CGFloat(progressRatio), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(12)
            .frame(width: 148)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(entry.data.surfaceColor)
            )
        }
        .padding(16)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Lock Screen Circular (Pixel-Perfect Alignment) ──
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 3.5)
                .frame(width: 44, height: 44)

            Circle()
                .trim(from: 0, to: CGFloat(max(0.01, progressRatio)))
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 44, height: 44)

            VStack(spacing: -1) {
                Text("\(daysRemaining)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("DAYS")
                    .font(.system(size: 7, weight: .heavy))
                    .tracking(0.5)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // ── Lock Screen Inline ──
    private var accessoryInlineView: some View {
        Text("\(daysRemaining)d Left · \(entry.data.missionTitle ?? "Milestone")")
    }
}

public struct MilestoneMissionWidget: Widget {
    public let kind: String = "MilestoneMissionWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MissionProvider()) { entry in
            MilestoneMissionWidgetView(entry: entry)
        }
        .configurationDisplayName("Mission Card")
        .description("Track your active mission countdown and top priority task.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    }
}
