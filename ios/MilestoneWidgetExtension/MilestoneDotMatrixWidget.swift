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

            // Dot Matrix (Adaptive 1:1 or sampled to fit bounds cleanly)
            let (dotCount, dotCols, dotSize, dotSpacing): (Int, Int, CGFloat, CGFloat) = {
                if totalDays <= 30 {
                    return (totalDays, 6, 6.0, 4.0)
                } else if totalDays <= 48 {
                    return (totalDays, 6, 5.0, 3.5)
                } else if totalDays <= 65 {
                    return (totalDays, 7, 4.5, 3.0)
                } else {
                    return (48, 6, 5.0, 3.5)
                }
            }()
            let elapsedSampled = totalDays > 0 ? (dotCount == totalDays ? daysElapsed : Int((Double(daysElapsed) / Double(totalDays)) * Double(dotCount))) : 0

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: dotSpacing), count: dotCols), spacing: dotSpacing) {
                ForEach(0..<dotCount, id: \.self) { i in
                    dotView(index: i, elapsedSampled: elapsedSampled, dotSize: dotSize)
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

            // Right Column: Dense Obsidian Matrix (Dynamic 1:1 up to 80 days)
            let (medDotCount, medCols, medDotSize, medSpacing): (Int, Int, CGFloat, CGFloat) = {
                if totalDays <= 50 {
                    return (totalDays, 10, 5.5, 4.0)
                } else if totalDays <= 80 {
                    // Perfect for 65-day missions: 10 columns x 7 rows
                    return (totalDays, 10, 4.8, 3.2)
                } else {
                    return (70, 10, 4.8, 3.2)
                }
            }()
            let medElapsedSampled = totalDays > 0 ? (medDotCount == totalDays ? daysElapsed : Int((Double(daysElapsed) / Double(totalDays)) * Double(medDotCount))) : 0

            VStack(alignment: .trailing, spacing: 4) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: medSpacing), count: medCols), spacing: medSpacing) {
                    ForEach(0..<medDotCount, id: \.self) { i in
                        dotView(index: i, elapsedSampled: medElapsedSampled, dotSize: medDotSize)
                    }
                }
                .frame(width: 150)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Large Widget (Flagship Dual-Pillar Matrix: Work on Left, Personal on Right) ──
    private var largeView: some View {
        HStack(spacing: 0) {
            // ── Left Column: Work Mission ──
            pillarColumnView(
                title: "WORK",
                icon: "briefcase.fill",
                accentColor: Color.white,
                payload: entry.data.workMissionPayload ?? fallbackWorkPayload
            )
            .padding(.trailing, 12)

            // ── Centered Subtle Hairline Divider ──
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1)
                .padding(.vertical, 4)

            // ── Right Column: Personal Mission ──
            pillarColumnView(
                title: "PERSONAL",
                icon: "leaf.fill",
                accentColor: Color(red: 0x10/255.0, green: 0xB9/255.0, blue: 0x81/255.0),
                payload: entry.data.personalMissionPayload ?? fallbackPersonalPayload
            )
            .padding(.leading, 12)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    private var fallbackWorkPayload: MissionWidgetPayload? {
        if entry.data.missionCategory != "personal", let title = entry.data.missionTitle, let target = entry.data.missionTargetDate, let created = entry.data.missionCreatedAt {
            return MissionWidgetPayload(
                title: title,
                targetDate: target,
                createdAt: created,
                category: "work",
                todosTotal: entry.data.missionTodosTotal,
                todosDone: entry.data.missionTodosDone,
                topPendingTaskText: entry.data.topPendingTaskText,
                topPendingTaskId: entry.data.topPendingTaskId
            )
        }
        return nil
    }

    private var fallbackPersonalPayload: MissionWidgetPayload? {
        // Strict Pro Gate: Non-Pro users never receive fallback personal payloads in widgets
        guard entry.data.isProUser else { return nil }

        if entry.data.missionCategory == "personal", let title = entry.data.missionTitle, let target = entry.data.missionTargetDate, let created = entry.data.missionCreatedAt {
            return MissionWidgetPayload(
                title: title,
                targetDate: target,
                createdAt: created,
                category: "personal",
                todosTotal: entry.data.missionTodosTotal,
                todosDone: entry.data.missionTodosDone,
                topPendingTaskText: entry.data.topPendingTaskText,
                topPendingTaskId: entry.data.topPendingTaskId
            )
        }
        return nil
    }

    // ── Dedicated Single Pillar Column for Large Dual Matrix ──
    @ViewBuilder
    private func pillarColumnView(
        title: String,
        icon: String,
        accentColor: Color,
        payload: MissionWidgetPayload?
    ) -> some View {
        if title == "PERSONAL" && !entry.data.isProUser {
            // ── Pro Locked State for Free Users ──
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(accentColor.opacity(0.6))
                        .frame(width: 5, height: 5)
                    Text("PERSONAL")
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(1.8)
                        .foregroundStyle(entry.data.textSecondaryColor)

                    Spacer()

                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 5) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0))

                    Text("MILESTONE PRO")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.0)
                        .foregroundStyle(entry.data.textPrimaryColor)

                    Text("Dual-Pillar Work & Personal parallel tracking requires Milestone Pro.")
                        .font(.system(size: 8.5, weight: .medium))
                        .lineSpacing(2)
                        .foregroundStyle(entry.data.textSecondaryColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("UPGRADE IN APP")
                        .font(.system(size: 7.5, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let payload = payload {
            let pDiff = Date(timeIntervalSince1970: payload.targetDate).timeIntervalSince(Date())
            let pRemaining = max(0, Int(ceil(pDiff / 86400.0)))
            let pTotalDiff = Date(timeIntervalSince1970: payload.targetDate).timeIntervalSince(Date(timeIntervalSince1970: payload.createdAt))
            let pTotal = max(1, Int(ceil(pTotalDiff / 86400.0)))
            let pElapsedDiff = Date().timeIntervalSince(Date(timeIntervalSince1970: payload.createdAt))
            let pElapsed = max(0, Int(floor(pElapsedDiff / 86400.0)))

            // Dynamic 1:1 Matrix Engine:
            // For missions up to 84 days (including 65-day runways), render exactly 1 dot per day!
            // Above 84 days, smoothly sample to keep layout crisp.
            let (dotCount, dotCols, dotSize, dotSpacing): (Int, Int, CGFloat, CGFloat) = {
                if pTotal <= 36 {
                    return (pTotal, 6, 5.5, 4.0)
                } else if pTotal <= 56 {
                    return (pTotal, 7, 5.0, 3.5)
                } else if pTotal <= 84 {
                    // Perfect for 65-day missions: 7 columns x 10 rows (up to 70-84 dots)
                    return (pTotal, 7, 4.5, 3.2)
                } else {
                    // Long-range runway: sample 70 dots
                    return (70, 7, 4.5, 3.2)
                }
            }()

            let elapsedSampled = pTotal > 0 ? (dotCount == pTotal ? pElapsed : Int((Double(pElapsed) / Double(pTotal)) * Double(dotCount))) : 0

            VStack(alignment: .leading, spacing: 0) {
                // Header Bar
                HStack(spacing: 4) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 5, height: 5)

                    Text(title)
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(1.8)
                        .foregroundStyle(entry.data.textSecondaryColor)

                    Spacer()

                    Text("\(pRemaining)D")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(entry.data.textPrimaryColor)
                }
                .padding(.bottom, 6)

                // Pure Dot Matrix (No dark rounded box behind dots)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: dotSpacing), count: dotCols), spacing: dotSpacing) {
                    ForEach(0..<dotCount, id: \.self) { i in
                        dotView(index: i, elapsedSampled: elapsedSampled, dotSize: dotSize)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 1)

                Spacer(minLength: 4)

                // Footer: Mission Details & Top Task
                VStack(alignment: .leading, spacing: 3) {
                    Text(payload.title)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(entry.data.textPrimaryColor)

                    if let topTask = payload.topPendingTaskText {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text(topTask)
                                .font(.system(size: 9.5, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(entry.data.textSecondaryColor)
                        }
                    } else {
                        let pct = pTotal > 0 ? Int((Double(pRemaining) / Double(pTotal)) * 100) : 0
                        Text("\(pRemaining)/\(pTotal)D · \(pct)% LEFT")
                            .font(.system(size: 7.5, weight: .heavy))
                            .tracking(0.8)
                            .foregroundStyle(entry.data.textTertiaryColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Elegant Obsidian Empty State
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(accentColor.opacity(0.6))
                        .frame(width: 5, height: 5)
                    Text(title)
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(1.8)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(entry.data.textTertiaryColor)

                    Text("No Active \(title.capitalized) Mission")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(entry.data.textSecondaryColor)

                    Text("Create a \(title.lowercased()) mission in app")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(entry.data.textTertiaryColor)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
