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

    private var isPersonal: Bool {
        entry.data.missionCategory == "personal"
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            case .accessoryRectangular:
                accessoryRectangularView
            case .accessoryCircular:
                accessoryCircularView
            default:
                smallView
            }
        }
        .widgetURL(URL(string: "milestone://mission"))
    }

    // ── Helper for Burning Dot Matrix Rendering ──
    @ViewBuilder
    private func dotView(index: Int, elapsedSampled: Int, dotSize: CGFloat) -> some View {
        if index < elapsedSampled {
            // Passed day: subtle faded track dot
            Circle()
                .fill(entry.data.trackColor.opacity(0.85))
                .frame(width: dotSize, height: dotSize)
        } else if index == elapsedSampled {
            // Active Current Day (Burning Dot): lit up with subtle white aura
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: dotSize + 3, height: dotSize + 3)

                Circle()
                    .fill(Color.white)
                    .frame(width: dotSize, height: dotSize)
            }
            .frame(width: dotSize, height: dotSize)
        } else {
            // Remaining day: brightly illuminated crisp white
            Circle()
                .fill(Color.white)
                .frame(width: dotSize, height: dotSize)
        }
    }

    // ── Small Widget (2x2 Matrix) ──
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                    Text(isPersonal ? "PERSONAL" : "RUNWAY")
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(2.0)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }

                Spacer()

                Text("\(daysRemaining)D")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(entry.data.textPrimaryColor)
            }
            .padding(.bottom, 8)

            // Dot Matrix (30 dots: 6 cols x 5 rows)
            let sampleCount = min(30, max(12, totalDays))
            let elapsedSampled = totalDays > 0 ? Int((Double(daysElapsed) / Double(totalDays)) * Double(sampleCount)) : 0

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                ForEach(0..<sampleCount, id: \.self) { i in
                    dotView(index: i, elapsedSampled: elapsedSampled, dotSize: 6)
                }
            }

            Spacer()

            // Footer
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.data.missionTitle ?? "Active Mission")
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(entry.data.textPrimaryColor)

                Text("\(daysRemaining) OF \(totalDays) DAYS LEFT")
                    .font(.system(size: 7.5, weight: .heavy))
                    .tracking(1.0)
                    .foregroundStyle(entry.data.textTertiaryColor)
            }
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
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                    Text(isPersonal ? "PERSONAL" : "MILESTONE")
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.data.missionTitle ?? "No active mission")
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(entry.data.textPrimaryColor)

                    Text("\(daysElapsed)/\(totalDays) DAYS PASSED")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(entry.data.textTertiaryColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right Column: Dense Obsidian Matrix (60 dots: 10 cols x 6 rows)
            let sampleCount = 60
            let elapsedSampled = totalDays > 0 ? Int((Double(daysElapsed) / Double(totalDays)) * Double(sampleCount)) : 0

            VStack(alignment: .trailing, spacing: 4) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                    ForEach(0..<sampleCount, id: \.self) { i in
                        dotView(index: i, elapsedSampled: elapsedSampled, dotSize: 5.5)
                    }
                }
                .frame(width: 145)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Large Widget (Full Runway Matrix) ──
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                    Text(isPersonal ? "PERSONAL RUNWAY" : "KEYSTONE RUNWAY")
                        .font(.system(size: 9.5, weight: .heavy))
                        .tracking(2.5)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("\(daysRemaining)")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(entry.data.textPrimaryColor)
                    Text("DAYS LEFT")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }
            }
            .padding(.bottom, 12)

            // Large Dense Matrix (96 dots: 12 cols x 8 rows)
            let sampleCount = 96
            let elapsedSampled = totalDays > 0 ? Int((Double(daysElapsed) / Double(totalDays)) * Double(sampleCount)) : 0

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 12), spacing: 5) {
                ForEach(0..<sampleCount, id: \.self) { i in
                    dotView(index: i, elapsedSampled: elapsedSampled, dotSize: 7)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(entry.data.surfaceColor.opacity(0.4))
            )

            Spacer()

            // Footer / Active Mission Stats
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.data.missionTitle ?? "Active Mission")
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(entry.data.textPrimaryColor)

                    if let topTask = entry.data.topPendingTaskText {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text(topTask)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(entry.data.textSecondaryColor)
                        }
                    }
                }

                Spacer()

                // Days Remaining Percentage
                let remainingPct = totalDays > 0 ? Int((Double(daysRemaining) / Double(totalDays)) * 100) : 0
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(remainingPct)%")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(entry.data.textPrimaryColor)
                    Text("REMAINING")
                        .font(.system(size: 7.5, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(entry.data.textTertiaryColor)
                }
            }
            .padding(.top, 8)
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
                    .font(.system(size: 11.5, weight: .bold))
                    .lineLimit(1)

                Spacer()

                Text("\(daysRemaining)d")
                    .font(.system(size: 12, weight: .black))
            }

            // Mini 2-row dot strip (16 dots): passed = faded, remaining = illuminated
            let sampleCount = 16
            let elapsedSampled = totalDays > 0 ? Int((Double(daysElapsed) / Double(totalDays)) * Double(sampleCount)) : 0
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 8), spacing: 3) {
                ForEach(0..<sampleCount, id: \.self) { i in
                    Circle()
                        .fill(i < elapsedSampled ? Color.white.opacity(0.20) : Color.white)
                        .frame(width: 4.5, height: 4.5)
                }
            }
            .padding(.top, 2)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // ── Lock Screen Circular (Runway Dot Ring) ──
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            let remainingRatio = totalDays > 0 ? min(1.0, Double(daysRemaining) / Double(totalDays)) : 1.0

            Circle()
                .stroke(Color.white.opacity(0.20), lineWidth: 3.5)
                .frame(width: 44, height: 44)

            Circle()
                .trim(from: 0, to: CGFloat(max(0.02, remainingRatio)))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 44, height: 44)

            VStack(spacing: -1) {
                Text("\(daysRemaining)")
                    .font(.system(size: 14, weight: .black))
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
}

public struct MilestoneDotMatrixWidget: Widget {
    public let kind: String = "MilestoneDotMatrixWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DotMatrixProvider()) { entry in
            MilestoneDotMatrixWidgetView(entry: entry)
        }
        .configurationDisplayName("Dot Matrix")
        .description("Pure visual dot matrix runway representing your active milestone countdown.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular])
    }
}
