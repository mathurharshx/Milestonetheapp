import WidgetKit
import SwiftUI

struct MomentumWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MomentumWidgetEntry {
        MomentumWidgetEntry(date: Date(), data: MilestoneWidgetData())
    }

    func getSnapshot(in context: Context, completion: @escaping (MomentumWidgetEntry) -> Void) {
        let data = SharedWidgetStore.load() ?? MilestoneWidgetData()
        completion(MomentumWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MomentumWidgetEntry>) -> Void) {
        let data = SharedWidgetStore.load() ?? MilestoneWidgetData()
        let entry = MomentumWidgetEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct MomentumWidgetEntry: TimelineEntry {
    let date: Date
    let data: MilestoneWidgetData
}

struct MilestoneMomentumWidgetView: View {
    let entry: MomentumWidgetEntry
    @Environment(\.widgetFamily) var family

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // ── Small Widget ──
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("MOMENTUM")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2.5)
                    .foregroundStyle(Color.secondary)

                Spacer()

                Image(systemName: "bolt.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.primary)
            }

            Spacer()

            // Large Streak Count
            Text("\(max(1, entry.data.focusStreak))")
                .font(.system(size: 42, weight: .bold))
                .tracking(-1)
                .foregroundStyle(Color.primary)

            Text("DAY STREAK")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Color.secondary)

            Spacer()

            // 7-day mini dot strip
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { i in
                    let level = (i < entry.data.weeklyFocusLevels.count) ? entry.data.weeklyFocusLevels[i] : 1
                    Circle()
                        .fill(level > 0 ? Color.primary.opacity(Double(level) * 0.3 + 0.1) : Color.primary.opacity(0.12))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // ── Medium Widget ──
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left Column: Streak & Daily Total
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("MOMENTUM")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(2.5)
                }
                .foregroundStyle(Color.secondary)

                Text("\(max(1, entry.data.focusStreak))")
                    .font(.system(size: 38, weight: .bold))
                    .tracking(-1)
                    .foregroundStyle(Color.primary)

                Text("DAY FOCUS STREAK")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Color.secondary)

                Spacer()

                if let quote = entry.data.quoteText {
                    Text("\"\(quote)\"")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .italic()
                        .lineLimit(2)
                        .foregroundStyle(Color.primary.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right Column: Weekly Focus Heatmap Matrix
            VStack(alignment: .leading, spacing: 6) {
                Text("THIS WEEK")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(Color.secondary)

                // 7 columns of 3 intensity dots
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { col in
                        let level = (col < entry.data.weeklyFocusLevels.count) ? entry.data.weeklyFocusLevels[col] : 1
                        VStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { row in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(row < level ? Color.primary : Color.primary.opacity(0.12))
                                    .frame(width: 10, height: 10)
                            }

                            Text(dayLabels[col])
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.secondary)
                                .padding(.top, 2)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
            )
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

public struct MilestoneMomentumWidget: Widget {
    public let kind: String = "MilestoneMomentumWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MomentumWidgetProvider()) { entry in
            MilestoneMomentumWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Momentum")
        .description("Track your daily focus streaks and weekly momentum heatmap.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
