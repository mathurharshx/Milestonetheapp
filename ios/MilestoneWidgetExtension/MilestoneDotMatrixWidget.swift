import WidgetKit
import SwiftUI

struct DotMatrixProvider: TimelineProvider {
    func placeholder(in context: Context) -> DotMatrixEntry {
        DotMatrixEntry(date: Date(), data: MilestoneWidgetData())
    }

    func getSnapshot(in context: Context, completion: @escaping (DotMatrixEntry) -> Void) {
        let data = SharedWidgetStore.load() ?? MilestoneWidgetData()
        completion(DotMatrixEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DotMatrixEntry>) -> Void) {
        let data = SharedWidgetStore.load() ?? MilestoneWidgetData()
        let entry = DotMatrixEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct DotMatrixEntry: TimelineEntry {
    let date: Date
    let data: MilestoneWidgetData
}

struct MilestoneDotMatrixWidgetView: View {
    let entry: DotMatrixEntry
    @Environment(\.widgetFamily) var family

    private var daysRemaining: Int {
        guard let target = entry.data.missionTargetDate else { return 0 }
        let diff = Date(timeIntervalSince1970: target).timeIntervalSince(Date())
        return max(0, Int(ceil(diff / 86400.0)))
    }

    private var totalDays: Int {
        guard let created = entry.data.missionCreatedAt,
              let target = entry.data.missionTargetDate else { return 30 }
        let diff = Date(timeIntervalSince1970: target).timeIntervalSince(Date(timeIntervalSince1970: created))
        return max(1, Int(ceil(diff / 86400.0)))
    }

    private var daysElapsed: Int {
        guard let created = entry.data.missionCreatedAt else { return 0 }
        let diff = Date().timeIntervalSince(Date(timeIntervalSince1970: created))
        return max(0, Int(floor(diff / 86400.0)))
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .accessoryRectangular:
                accessoryRectangularView
            default:
                smallView
            }
        }
        .widgetURL(URL(string: "milestone://mission"))
    }

    // ── Small Widget (2x2 Matrix) ──
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("MATRIX")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2.5)
                    .foregroundStyle(entry.data.textSecondaryColor)

                Spacer()

                Text("\(daysRemaining)D")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(entry.data.textPrimaryColor)
            }
            .padding(.bottom, 8)

            // Dot Matrix (30 dots: 6 cols x 5 rows)
            let sampleCount = min(30, max(12, totalDays))
            let elapsedSampled = totalDays > 0 ? Int((Double(daysElapsed) / Double(totalDays)) * Double(sampleCount)) : 0

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                ForEach(0..<sampleCount, id: \.self) { i in
                    Circle()
                        .fill(i < elapsedSampled ? entry.data.textPrimaryColor.opacity(0.85) : (i == elapsedSampled ? entry.data.textPrimaryColor : entry.data.trackColor))
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()

            // Footer
            Text(entry.data.missionTitle ?? "Active Mission")
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(entry.data.textPrimaryColor)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Medium Widget (4x2 Matrix Banner) ──
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left Column: Countdown Details
            VStack(alignment: .leading, spacing: 4) {
                Text("MILESTONE")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2.5)
                    .foregroundStyle(entry.data.textSecondaryColor)

                Text("\(daysRemaining)")
                    .font(.system(size: 38, weight: .bold))
                    .tracking(-1)
                    .foregroundStyle(entry.data.textPrimaryColor)

                Text("DAYS LEFT")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(entry.data.textSecondaryColor)

                Spacer()

                Text(entry.data.missionTitle ?? "No active mission")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(entry.data.textPrimaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right Column: Dense Obsidian Matrix (60 dots: 10 cols x 6 rows)
            let sampleCount = 60
            let elapsedSampled = totalDays > 0 ? Int((Double(daysElapsed) / Double(totalDays)) * Double(sampleCount)) : 0

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(0..<sampleCount, id: \.self) { i in
                    Circle()
                        .fill(i < elapsedSampled ? entry.data.textPrimaryColor.opacity(0.85) : (i == elapsedSampled ? entry.data.textPrimaryColor : entry.data.trackColor))
                        .frame(width: 5.5, height: 5.5)
                }
            }
            .frame(width: 140)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Lock Screen Rectangular (Pixel-Perfect Alignment) ──
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(entry.data.missionTitle ?? "Milestone")
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)

                Spacer()

                Text("\(daysRemaining)d")
                    .font(.system(size: 12, weight: .bold))
            }

            // Mini 2-row dot strip (16 dots)
            let sampleCount = 16
            let elapsedSampled = totalDays > 0 ? Int((Double(daysElapsed) / Double(totalDays)) * Double(sampleCount)) : 0
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 8), spacing: 3) {
                ForEach(0..<sampleCount, id: \.self) { i in
                    Circle()
                        .fill(i < elapsedSampled ? Color.white : Color.white.opacity(0.25))
                        .frame(width: 4.5, height: 4.5)
                }
            }
            .padding(.top, 2)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

public struct MilestoneDotMatrixWidget: Widget {
    public let kind: String = "MilestoneDotMatrixWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DotMatrixProvider()) { entry in
            MilestoneDotMatrixWidgetView(entry: entry)
        }
        .configurationDisplayName("Dot Matrix")
        .description("Pure visual dot matrix representation of your active milestone.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
