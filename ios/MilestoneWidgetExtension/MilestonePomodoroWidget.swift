import WidgetKit
import SwiftUI
import AppIntents

public struct TogglePomodoroWidgetIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Pomodoro"
    public static var description = IntentDescription("Start or pause the focus timer directly from widget")

    public init() {}

    public func perform() async throws -> some IntentResult {
        if var data = SharedWidgetStore.load() {
            let wasRunning = data.pomodoroIsRunning
            data.pomodoroIsRunning = !wasRunning
            if !wasRunning {
                // Starting focus session
                let duration = data.pomodoroTimeRemaining > 0 ? data.pomodoroTimeRemaining : (data.pomodoroTotalTime > 0 ? data.pomodoroTotalTime : 1500)
                let target = Date().addingTimeInterval(TimeInterval(duration))
                data.pomodoroTimeRemaining = duration
                data.pomodoroTargetEndTime = target.timeIntervalSince1970
            } else {
                // Pausing focus session
                if let target = data.pomodoroTargetEndTime {
                    let diff = max(0, Int(ceil(Date(timeIntervalSince1970: target).timeIntervalSinceNow)))
                    data.pomodoroTimeRemaining = diff
                }
                data.pomodoroTargetEndTime = nil
            }
            data.lastUpdated = Date().timeIntervalSince1970
            SharedWidgetStore.save(data)
        }
        return .result()
    }
}

public struct ResetPomodoroWidgetIntent: AppIntent {
    public static var title: LocalizedStringResource = "Reset Pomodoro"
    public static var description = IntentDescription("Reset the focus timer to start of cycle")

    public init() {}

    public func perform() async throws -> some IntentResult {
        if var data = SharedWidgetStore.load() {
            data.pomodoroIsRunning = false
            data.pomodoroPhase = "focus"
            data.pomodoroSession = 1
            data.pomodoroTimeRemaining = data.pomodoroTotalTime > 0 ? data.pomodoroTotalTime : 1500
            data.pomodoroTargetEndTime = nil
            data.lastUpdated = Date().timeIntervalSince1970
            SharedWidgetStore.save(data)
        }
        return .result()
    }
}

struct PomodoroWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PomodoroWidgetEntry {
        PomodoroWidgetEntry(date: Date(), data: MilestoneWidgetData())
    }

    func getSnapshot(in context: Context, completion: @escaping (PomodoroWidgetEntry) -> Void) {
        let data = SharedWidgetStore.load() ?? MilestoneWidgetData()
        completion(PomodoroWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PomodoroWidgetEntry>) -> Void) {
        let data = SharedWidgetStore.load() ?? MilestoneWidgetData()
        let entry = PomodoroWidgetEntry(date: Date(), data: data)

        let nextUpdate: Date
        if data.pomodoroIsRunning, let target = data.pomodoroTargetEndTime, target > Date().timeIntervalSince1970 {
            // Refresh when countdown completes
            nextUpdate = Date(timeIntervalSince1970: target)
        } else {
            nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        }
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct PomodoroWidgetEntry: TimelineEntry {
    let date: Date
    let data: MilestoneWidgetData
}

struct MilestonePomodoroWidgetView: View {
    let entry: PomodoroWidgetEntry
    @Environment(\.widgetFamily) var family

    private var currentRemainingSeconds: Int {
        if entry.data.pomodoroIsRunning, let target = entry.data.pomodoroTargetEndTime {
            let diff = Int(ceil(Date(timeIntervalSince1970: target).timeIntervalSince(entry.date)))
            return max(0, diff)
        }
        return entry.data.pomodoroTimeRemaining
    }

    private var progressRatio: Double {
        let total = entry.data.pomodoroTotalTime > 0 ? entry.data.pomodoroTotalTime : 1500
        let remaining = currentRemainingSeconds
        let elapsed = max(0, total - remaining)
        return min(1.0, max(0.0, Double(elapsed) / Double(total)))
    }

    private var formattedTime: String {
        let seconds = currentRemainingSeconds
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var phaseTitle: String {
        switch entry.data.pomodoroPhase {
        case "shortBreak": return "Short Break"
        case "longBreak": return "Long Break"
        default: return "Focus Session"
        }
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryCircular:
            accessoryCircularView
        default:
            smallView
        }
    }

    // ── Small Widget (Live Hardware Ring) ──
    private var smallView: some View {
        VStack(spacing: 0) {
            // Top Section Header
            HStack {
                Text(phaseTitle.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(entry.data.textSecondaryColor)

                Spacer()

                Text("\(entry.data.pomodoroSession)/\(entry.data.pomodoroTotalSessions)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(entry.data.textSecondaryColor)
            }
            .padding(.bottom, 6)

            Spacer(minLength: 2)

            // Precision Ring
            ZStack {
                // Background Track
                Circle()
                    .stroke(entry.data.trackColor, lineWidth: 5.5)
                    .frame(width: 74, height: 74)

                // Active Progress Arc
                Circle()
                    .trim(from: 0, to: CGFloat(max(0.01, progressRatio)))
                    .stroke(
                        entry.data.textPrimaryColor,
                        style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 74, height: 74)

                // Real-Time Live Ticking Countdown on Home Screen
                if entry.data.pomodoroIsRunning, let target = entry.data.pomodoroTargetEndTime, target > Date().timeIntervalSince1970 {
                    Text(timerInterval: Date()...Date(timeIntervalSince1970: target), countsDown: true)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(entry.data.textPrimaryColor)
                        .multilineTextAlignment(.center)
                        .frame(width: 58)
                } else {
                    Text(formattedTime)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(entry.data.textPrimaryColor)
                        .multilineTextAlignment(.center)
                        .frame(width: 58)
                }
            }
            .frame(width: 76, height: 76)

            Spacer(minLength: 2)

            // Tactile Interactive Start/Pause Button
            Button(intent: TogglePomodoroWidgetIntent()) {
                HStack(spacing: 5) {
                    Image(systemName: entry.data.pomodoroIsRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 9, weight: .heavy))

                    Text(entry.data.pomodoroIsRunning ? "PAUSE" : "START")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.5)
                }
                .foregroundStyle(entry.data.isDarkMode ? Color(red: 0x22/255.0, green: 0x22/255.0, blue: 0x22/255.0) : Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(entry.data.textPrimaryColor)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Medium Widget (Banner Layout) ──
    private var mediumView: some View {
        HStack(spacing: 20) {
            // Left: Large Precision Ring
            ZStack {
                Circle()
                    .stroke(entry.data.trackColor, lineWidth: 6.5)
                    .frame(width: 90, height: 90)

                Circle()
                    .trim(from: 0, to: CGFloat(max(0.01, progressRatio)))
                    .stroke(
                        entry.data.textPrimaryColor,
                        style: StrokeStyle(lineWidth: 6.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 90, height: 90)

                if entry.data.pomodoroIsRunning, let target = entry.data.pomodoroTargetEndTime, target > Date().timeIntervalSince1970 {
                    Text(timerInterval: Date()...Date(timeIntervalSince1970: target), countsDown: true)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(entry.data.textPrimaryColor)
                        .multilineTextAlignment(.center)
                        .frame(width: 70)
                } else {
                    Text(formattedTime)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(entry.data.textPrimaryColor)
                        .multilineTextAlignment(.center)
                        .frame(width: 70)
                }
            }
            .frame(width: 92, height: 92)

            // Right: Information and Controls
            VStack(alignment: .leading, spacing: 5) {
                Text("POMODORO")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2.5)
                    .foregroundStyle(entry.data.textSecondaryColor)

                Text(phaseTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(entry.data.textPrimaryColor)

                // Session Indicator Dots (4 dots)
                HStack(spacing: 6) {
                    ForEach(1...entry.data.pomodoroTotalSessions, id: \.self) { s in
                        Circle()
                            .fill(s <= entry.data.pomodoroSession ? entry.data.textPrimaryColor : entry.data.trackColor)
                            .frame(width: 6, height: 6)
                    }
                    Text("Session \(entry.data.pomodoroSession) of \(entry.data.pomodoroTotalSessions)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(entry.data.textSecondaryColor)
                }
                .padding(.bottom, 4)

                Spacer()

                // Dual Interactive Buttons
                HStack(spacing: 8) {
                    Button(intent: TogglePomodoroWidgetIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: entry.data.pomodoroIsRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text(entry.data.pomodoroIsRunning ? "PAUSE" : "START")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                        }
                        .foregroundStyle(entry.data.isDarkMode ? Color(red: 0x22/255.0, green: 0x22/255.0, blue: 0x22/255.0) : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(entry.data.textPrimaryColor)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(intent: ResetPomodoroWidgetIntent()) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(entry.data.textPrimaryColor)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(entry.data.surfaceColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            entry.data.backgroundColor
        }
    }

    // ── Lock Screen Circular ──
    private var accessoryCircularView: some View {
        ZStack {
            Gauge(value: progressRatio) {
                Image(systemName: "hourglass")
            } currentValueLabel: {
                if entry.data.pomodoroIsRunning, let target = entry.data.pomodoroTargetEndTime, target > Date().timeIntervalSince1970 {
                    Text(timerInterval: Date()...Date(timeIntervalSince1970: target), countsDown: true)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                } else {
                    Text(formattedTime)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
        }
    }
}

public struct MilestonePomodoroWidget: Widget {
    public let kind: String = "MilestonePomodoroWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroWidgetProvider()) { entry in
            MilestonePomodoroWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Timer")
        .description("Interactive Pomodoro focus timer with live start/pause controls.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}
