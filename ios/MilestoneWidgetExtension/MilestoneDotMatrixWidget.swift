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
        let schedule = WidgetDateCalculations.generateMidnightSchedule(from: Date(), daysAhead: 4)
        let entries = schedule.map { DotMatrixEntry(date: $0, data: data) }
        // Next update scheduled after the last generated midnight
        let nextUpdate = schedule.last ?? Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }
}

struct DotMatrixEntry: TimelineEntry {
    let date: Date
    let data: MilestoneWidgetData
}

struct MilestoneDotMatrixWidgetView: View {
    let entry: DotMatrixEntry
    @Environment(\.widgetFamily) var family

    private var payload: MissionWidgetPayload? {
        if let w = entry.data.workMissionPayload { return w }
        if entry.data.missionCategory != "personal", let title = entry.data.missionTitle, let target = entry.data.missionTargetDate, let created = entry.data.missionCreatedAt {
            return MissionWidgetPayload(title: title, targetDate: target, createdAt: created, category: "work")
        }
        return nil
    }

    private var daysRemaining: Int {
        if let p = payload {
            let targetDate = Date(timeIntervalSince1970: p.targetDate)
            return WidgetDateCalculations.daysRemaining(targetDate: targetDate, asOf: entry.date)
        }
        guard let target = entry.data.missionTargetDate else { return 0 }
        let targetDate = Date(timeIntervalSince1970: target)
        return WidgetDateCalculations.daysRemaining(targetDate: targetDate, asOf: entry.date)
    }

    private var totalDays: Int {
        if let p = payload {
            let createdDate = Date(timeIntervalSince1970: p.createdAt)
            let targetDate = Date(timeIntervalSince1970: p.targetDate)
            return WidgetDateCalculations.totalDays(createdAt: createdDate, targetDate: targetDate)
        }
        guard let created = entry.data.missionCreatedAt,
              let target = entry.data.missionTargetDate else { return 30 }
        let createdDate = Date(timeIntervalSince1970: created)
        let targetDate = Date(timeIntervalSince1970: target)
        return WidgetDateCalculations.totalDays(createdAt: createdDate, targetDate: targetDate)
    }

    private var daysElapsed: Int {
        if let p = payload {
            let createdDate = Date(timeIntervalSince1970: p.createdAt)
            return WidgetDateCalculations.daysElapsed(createdAt: createdDate, asOf: entry.date)
        }
        guard let created = entry.data.missionCreatedAt else { return 0 }
        let createdDate = Date(timeIntervalSince1970: created)
        return WidgetDateCalculations.daysElapsed(createdAt: createdDate, asOf: entry.date)
    }

    private var missionTitle: String {
        payload?.title ?? entry.data.missionTitle ?? "Work Mission"
    }

    private var isPersonal: Bool {
        false // Dedicated Work Widget
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
    public static func renderDot(index: Int, elapsedSampled: Int, dotSize: CGFloat) -> some View {
        if index < elapsedSampled {
            // Passed day: clearly defined, muted silver/graphite dot (crisply visible on dark background)
            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: dotSize, height: dotSize)
        } else if index == elapsedSampled {
            // Active Current Day (Burning Dot): lit up with subtle white aura
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: dotSize + 3.5, height: dotSize + 3.5)

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

    private func dotView(index: Int, elapsedSampled: Int, dotSize: CGFloat) -> some View {
        Self.renderDot(index: index, elapsedSampled: elapsedSampled, dotSize: dotSize)
    }

    // ── Universal Adaptive Grid Engine (1 to 150+ Days) ──
    public static func calculateGrid(totalDays: Int, isHalfColumn: Bool = false) -> (dotCount: Int, cols: Int, size: CGFloat, spacing: CGFloat) {
        if isHalfColumn {
            // For half-column layouts (Dual-Pillar large widget: ~148pt column width, full vertical height)
            if totalDays <= 15 {
                return (totalDays, 4, 11.5, 9.0)
            } else if totalDays <= 35 {
                return (totalDays, 5, 9.5, 7.5)
            } else if totalDays <= 65 {
                return (totalDays, 6, 8.0, 6.2)
            } else if totalDays <= 100 {
                // Perfect for 70, 84, 90, 100 days: 7 columns (7-day calendar week!), 6.5pt dots, 5.0pt spacing
                return (totalDays, 7, 6.5, 5.0)
            } else {
                // 101+ Days: 100-dot milestone percentage heat matrix (10x10)
                return (100, 10, 5.5, 4.0)
            }
        } else {
            // For standard small or full-width widgets
            if totalDays <= 15 {
                return (totalDays, 5, 9.0, 6.0)
            } else if totalDays <= 35 {
                return (totalDays, 6, 7.4, 5.0)
            } else if totalDays <= 65 {
                return (totalDays, 7, 5.8, 4.0)
            } else if totalDays <= 100 {
                return (totalDays, 10, 5.0, 3.2)
            } else {
                return (100, 10, 5.0, 3.2)
            }
        }
    }

    // ── Small Widget (Ultra-Minimalist: Pure Dots + Mission Title Only) ──
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dot Matrix (Adaptive 1:1 with dynamically scaled dots)
            let config = Self.calculateGrid(totalDays: totalDays, isHalfColumn: false)
            let elapsedSampled = totalDays > 0 ? (config.dotCount == totalDays ? daysElapsed : Int((Double(daysElapsed) / Double(totalDays)) * Double(config.dotCount))) : 0

            Spacer(minLength: 2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: config.spacing), count: config.cols), spacing: config.spacing) {
                ForEach(0..<config.dotCount, id: \.self) { i in
                    dotView(index: i, elapsedSampled: elapsedSampled, dotSize: config.size)
                }
            }

            Spacer(minLength: 6)

            // Footer: Mission Title Only (Clean, zero clutter)
            Text(missionTitle)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
                .foregroundStyle(entry.data.textPrimaryColor)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Medium Widget (4x2 Matrix Banner) ──
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left Column: Countdown Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                    Text("WORK")
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(2.0)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }

                Text("\(daysRemaining)")
                    .font(.system(size: 38, weight: .bold))
                    .tracking(-1)
                    .foregroundStyle(entry.data.textPrimaryColor)

                // Clean header: Zero text truncation
                Text("\(daysRemaining)D LEFT")
                    .font(.system(size: 8.5, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(entry.data.textSecondaryColor)

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text(missionTitle)
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

            // Right Column: Dense Obsidian Matrix
            let config = Self.calculateGrid(totalDays: totalDays, isHalfColumn: true)
            let elapsedSampled = totalDays > 0 ? (config.dotCount == totalDays ? daysElapsed : Int((Double(daysElapsed) / Double(totalDays)) * Double(config.dotCount))) : 0

            VStack(alignment: .trailing, spacing: 4) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: config.spacing), count: config.cols), spacing: config.spacing) {
                    ForEach(0..<config.dotCount, id: \.self) { i in
                        dotView(index: i, elapsedSampled: elapsedSampled, dotSize: config.size)
                    }
                }
                .frame(width: 154)
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
            let pTargetDate = Date(timeIntervalSince1970: payload.targetDate)
            let pCreatedDate = Date(timeIntervalSince1970: payload.createdAt)
            let pTotal = WidgetDateCalculations.totalDays(createdAt: pCreatedDate, targetDate: pTargetDate)
            let pElapsed = WidgetDateCalculations.daysElapsed(createdAt: pCreatedDate, asOf: entry.date)

            // Dynamic scaling in Dual Pillar: 1:1 up to 100 days; 100-dot milestone % over 100 days
            let config = Self.calculateGrid(totalDays: pTotal, isHalfColumn: true)
            let elapsedSampled = pTotal > 0 ? (config.dotCount == pTotal ? pElapsed : Int((Double(pElapsed) / Double(pTotal)) * Double(config.dotCount))) : 0

            VStack(alignment: .leading, spacing: 0) {
                // Header Bar (Pure Pillar Label Only - no wrapping)
                HStack(spacing: 5) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 5, height: 5)

                    Text(title)
                        .font(.system(size: 9.0, weight: .heavy))
                        .tracking(2.0)
                        .foregroundStyle(entry.data.textSecondaryColor)

                    Spacer(minLength: 0)
                }
                .padding(.bottom, 10)

                // Pure Dot Matrix: Spanning Full Height of Pillar
                Spacer(minLength: 0)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: config.spacing), count: config.cols), spacing: config.spacing) {
                    ForEach(0..<config.dotCount, id: \.self) { i in
                        dotView(index: i, elapsedSampled: elapsedSampled, dotSize: config.size)
                    }
                }
                .padding(.horizontal, 1)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Elegant Obsidian Empty State
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(accentColor.opacity(0.6))
                        .frame(width: 5, height: 5)

                    Text(title)
                        .font(.system(size: 9.0, weight: .heavy))
                        .tracking(2.0)
                        .foregroundStyle(entry.data.textSecondaryColor)

                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(entry.data.textTertiaryColor)

                    Text("No Active \(title.capitalized) Mission")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(entry.data.textSecondaryColor)

                    Text("Create in app")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(entry.data.textTertiaryColor)
                }

                Spacer(minLength: 0)
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
                        .fill(i < elapsedSampled ? Color.white.opacity(0.24) : Color.white)
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

// ─────────────────────────────────────────────────────────────
// MARK: - Dedicated Clean Pillar Dot Matrix View (Personal Mission Pro)
// ─────────────────────────────────────────────────────────────
public struct CleanPillarDotMatrixView: View {
    let entry: DotMatrixEntry
    let pillar: String // "personal"
    @Environment(\.widgetFamily) var family

    private var isPersonal: Bool { pillar == "personal" }

    private var payload: MissionWidgetPayload? {
        if let p = entry.data.personalMissionPayload { return p }
        if entry.data.missionCategory == "personal", let t = entry.data.missionTitle, let target = entry.data.missionTargetDate, let created = entry.data.missionCreatedAt {
            return MissionWidgetPayload(title: t, targetDate: target, createdAt: created, category: "personal")
        }
        return nil
    }

    private var daysRemaining: Int {
        guard let p = payload else { return 0 }
        let target = Date(timeIntervalSince1970: p.targetDate)
        return WidgetDateCalculations.daysRemaining(targetDate: target, asOf: entry.date)
    }

    private var totalDays: Int {
        guard let p = payload else { return 30 }
        let created = Date(timeIntervalSince1970: p.createdAt)
        let target = Date(timeIntervalSince1970: p.targetDate)
        return WidgetDateCalculations.totalDays(createdAt: created, targetDate: target)
    }

    private var daysElapsed: Int {
        guard let p = payload else { return 0 }
        let created = Date(timeIntervalSince1970: p.createdAt)
        return WidgetDateCalculations.daysElapsed(createdAt: created, asOf: entry.date)
    }

    public var body: some View {
        Group {
            if isPersonal && !entry.data.isProUser {
                lockedProView
            } else if let _ = payload {
                switch family {
                case .systemSmall:
                    cleanSmallView
                case .systemMedium:
                    cleanMediumView
                case .accessoryRectangular:
                    cleanAccessoryRectangularView
                case .accessoryCircular:
                    cleanAccessoryCircularView
                default:
                    cleanSmallView
                }
            } else {
                emptyPillarView
            }
        }
        .widgetURL(URL(string: isPersonal ? "milestone://personal" : "milestone://mission"))
    }

    // ── Pure Minimalist Small: Clean Dot Matrix + Title (No redundant days remaining text) ──
    private var cleanSmallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let config = MilestoneDotMatrixWidgetView.calculateGrid(totalDays: totalDays, isHalfColumn: false)
            let elapsedSampled = totalDays > 0 ? (config.dotCount == totalDays ? daysElapsed : Int((Double(daysElapsed) / Double(totalDays)) * Double(config.dotCount))) : 0

            Spacer(minLength: 2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: config.spacing), count: config.cols), spacing: config.spacing) {
                ForEach(0..<config.dotCount, id: \.self) { i in
                    MilestoneDotMatrixWidgetView.renderDot(index: i, elapsedSampled: elapsedSampled, dotSize: config.size)
                }
            }

            Spacer(minLength: 6)

            // Mission Title Only
            Text(payload?.title ?? "Personal Mission")
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
                .foregroundStyle(entry.data.textPrimaryColor)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Pure Minimalist Medium: Clean Left Countdown + Dense Dot Matrix ──
    private var cleanMediumView: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 0x10/255.0, green: 0xB9/255.0, blue: 0x81/255.0))
                        .frame(width: 5, height: 5)

                    Text("PERSONAL")
                        .font(.system(size: 8.5, weight: .heavy))
                        .tracking(2.2)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }

                Spacer()

                Text("\(daysRemaining)")
                    .font(.system(size: 44, weight: .black))
                    .tracking(-1.5)
                    .foregroundStyle(entry.data.textPrimaryColor)

                Text("\(daysRemaining)D LEFT")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.6)
                    .foregroundStyle(entry.data.textSecondaryColor)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right Dot Matrix
            let config = MilestoneDotMatrixWidgetView.calculateGrid(totalDays: totalDays, isHalfColumn: true)
            let medElapsedSampled = totalDays > 0 ? (config.dotCount == totalDays ? daysElapsed : Int((Double(daysElapsed) / Double(totalDays)) * Double(config.dotCount))) : 0

            VStack(alignment: .trailing) {
                Spacer()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: config.spacing), count: config.cols), spacing: config.spacing) {
                    ForEach(0..<config.dotCount, id: \.self) { i in
                        MilestoneDotMatrixWidgetView.renderDot(index: i, elapsedSampled: medElapsedSampled, dotSize: config.size)
                    }
                }
                .frame(width: 154)
                Spacer()
            }
        }
        .padding(18)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Accessory Rectangular ──
    private var cleanAccessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("PERSONAL")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)

                Spacer()

                Text("\(daysRemaining)d")
                    .font(.system(size: 13, weight: .black))
            }

            let sampleCount = 16
            let elapsedSampled = totalDays > 0 ? Int((Double(daysElapsed) / Double(totalDays)) * Double(sampleCount)) : 0
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 8), spacing: 3) {
                ForEach(0..<sampleCount, id: \.self) { i in
                    Circle()
                        .fill(i < elapsedSampled ? Color.white.opacity(0.24) : Color.white)
                        .frame(width: 4.5, height: 4.5)
                }
            }
            .padding(.top, 2)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // ── Accessory Circular ──
    private var cleanAccessoryCircularView: some View {
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

                Text("PERS")
                    .font(.system(size: 7, weight: .heavy))
                    .tracking(0.5)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // ── Pro Locked View for Personal Widget ──
    private var lockedProView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(red: 0x10/255.0, green: 0xB9/255.0, blue: 0x81/255.0))
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

            Image(systemName: "crown.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0))

            Text("MILESTONE PRO")
                .font(.system(size: 10.5, weight: .black))
                .tracking(1.2)
                .foregroundStyle(entry.data.textPrimaryColor)

            Text("Personal pillar countdown requires Milestone Pro.")
                .font(.system(size: 8.5, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(entry.data.textSecondaryColor)

            Spacer()
        }
        .padding(14)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Empty State View ──
    private var emptyPillarView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(red: 0x10/255.0, green: 0xB9/255.0, blue: 0x81/255.0))
                    .frame(width: 5, height: 5)
                Text("PERSONAL")
                    .font(.system(size: 8.5, weight: .heavy))
                    .tracking(1.8)
                    .foregroundStyle(entry.data.textSecondaryColor)
                Spacer()
            }

            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(entry.data.textTertiaryColor)

            Text("No Active Personal Mission")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(entry.data.textSecondaryColor)

            Spacer()
        }
        .padding(14)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Flagship Large Full-Screen Aesthetic Runway Widget
// ─────────────────────────────────────────────────────────────
public struct FullPageRunwayWidgetView: View {
    let entry: DotMatrixEntry
    let pillar: String // "work" | "personal"

    private var isPersonal: Bool { pillar == "personal" }

    private var payload: MissionWidgetPayload? {
        if isPersonal {
            if let p = entry.data.personalMissionPayload { return p }
            if entry.data.missionCategory == "personal", let t = entry.data.missionTitle, let target = entry.data.missionTargetDate, let created = entry.data.missionCreatedAt {
                return MissionWidgetPayload(title: t, targetDate: target, createdAt: created, category: "personal")
            }
            return nil
        } else {
            if let w = entry.data.workMissionPayload { return w }
            if entry.data.missionCategory != "personal", let t = entry.data.missionTitle, let target = entry.data.missionTargetDate, let created = entry.data.missionCreatedAt {
                return MissionWidgetPayload(title: t, targetDate: target, createdAt: created, category: "work")
            }
            return nil
        }
    }

    private var daysRemaining: Int {
        guard let p = payload else { return 0 }
        let target = Date(timeIntervalSince1970: p.targetDate)
        return WidgetDateCalculations.daysRemaining(targetDate: target, asOf: entry.date)
    }

    private var totalDays: Int {
        guard let p = payload else { return 30 }
        let created = Date(timeIntervalSince1970: p.createdAt)
        let target = Date(timeIntervalSince1970: p.targetDate)
        return WidgetDateCalculations.totalDays(createdAt: created, targetDate: target)
    }

    private var daysElapsed: Int {
        guard let p = payload else { return 0 }
        let created = Date(timeIntervalSince1970: p.createdAt)
        return WidgetDateCalculations.daysElapsed(createdAt: created, asOf: entry.date)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Top Header Single Line: Left Title + Right Days Left ──
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isPersonal ? Color(red: 0x10/255.0, green: 0xB9/255.0, blue: 0x81/255.0) : Color.white)
                        .frame(width: 6, height: 6)

                    Text(isPersonal ? "PERSONAL" : "WORK")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2.5)
                        .foregroundStyle(entry.data.textSecondaryColor)
                }

                Spacer()

                Text("\(daysRemaining)D LEFT")
                    .font(.system(size: 12, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(entry.data.textPrimaryColor)
            }
            .padding(.bottom, 14)

            // ── Entire Rest of Canvas: Sprawling Aesthetic Obsidian Runway ──
            let (dotCount, dotCols, dotSize, dotSpacing): (Int, Int, CGFloat, CGFloat) = {
                if totalDays <= 20 {
                    return (totalDays, 5, 13.0, 10.0)
                } else if totalDays <= 45 {
                    return (totalDays, 7, 10.5, 7.5)
                } else if totalDays <= 75 {
                    return (totalDays, 9, 8.5, 5.5)
                } else if totalDays <= 100 {
                    return (totalDays, 10, 7.5, 4.5)
                } else {
                    return (100, 10, 7.5, 4.5)
                }
            }()

            let elapsedSampled = totalDays > 0 ? (dotCount == totalDays ? daysElapsed : Int((Double(daysElapsed) / Double(totalDays)) * Double(dotCount))) : 0

            Spacer(minLength: 0)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: dotSpacing), count: dotCols), spacing: dotSpacing) {
                ForEach(0..<dotCount, id: \.self) { i in
                    MilestoneDotMatrixWidgetView.renderDot(index: i, elapsedSampled: elapsedSampled, dotSize: dotSize)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
        .widgetURL(URL(string: isPersonal ? "milestone://personal" : "milestone://mission"))
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Widget Structs
// ─────────────────────────────────────────────────────────────

public struct MilestoneDotMatrixWidget: Widget {
    public let kind: String = "MilestoneDotMatrixWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DotMatrixProvider()) { entry in
            MilestoneDotMatrixWidgetView(entry: entry)
        }
        .configurationDisplayName("Work Dot Matrix")
        .description("Pure visual dot matrix runway for your active Work mission countdown.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular])
    }
}

public struct MilestonePersonalDotMatrixWidget: Widget {
    public let kind: String = "MilestonePersonalDotMatrixWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DotMatrixProvider()) { entry in
            CleanPillarDotMatrixView(entry: entry, pillar: "personal")
        }
        .configurationDisplayName("Personal Countdown")
        .description("Ultra-clean dots and countdown for your active Personal mission (Milestone Pro).")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

public struct MilestoneFullRunwayWidget: Widget {
    public let kind: String = "MilestoneFullRunwayWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DotMatrixProvider()) { entry in
            FullPageRunwayWidgetView(entry: entry, pillar: entry.data.missionCategory == "personal" ? "personal" : "work")
        }
        .configurationDisplayName("Full Obsidian Runway")
        .description("Flagship full-page aesthetic dot runway for your active milestone.")
        .supportedFamilies([.systemLarge])
    }
}


