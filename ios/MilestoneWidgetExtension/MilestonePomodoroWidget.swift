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
                // Starting
                let target = Date().addingTimeInterval(TimeInterval(data.pomodoroTimeRemaining))
                data.pomodoroTargetEndTime = target.timeIntervalSince1970
            } else {
                // Pausing
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
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
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

    private var progressRatio: Double {
        let total = entry.data.pomodoroTotalTime
        guard total > 0 else { return 0 }
        let remaining = entry.data.pomodoroTimeRemaining
        let elapsed = max(0, total - remaining)
        return min(1.0, max(0.0, Double(elapsed) / Double(total)))
    }

    private var formattedTime: String {
        let seconds = entry.data.pomodoroTimeRemaining
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

    // ── Small Widget ──
    private var smallView: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(phaseTitle.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(Color.secondary)

                Spacer()

                Text("\(entry.data.pomodoroSession)/\(entry.data.pomodoroTotalSessions)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            // Circular Ring with Countdown
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 5)
                    .frame(width: 68, height: 68)

                Circle()
                    .trim(from: 0, to: CGFloat(progressRatio))
                    .stroke(
                        Color.primary,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 68, height: 68)

                if entry.data.pomodoroIsRunning, let target = entry.data.pomodoroTargetEndTime {
                    Text(timerInterval: Date()...Date(timeIntervalSince1970: target), countsDown: true)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.primary)
                } else {
                    Text(formattedTime)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.primary)
                }
            }

            Spacer()

            // Interactive Start/Pause Button (iOS 17+)
            Button(intent: TogglePomodoroWidgetIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: entry.data.pomodoroIsRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(entry.data.pomodoroIsRunning ? "PAUSE" : "START")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                }
                .foregroundStyle(entry.data.pomodoroIsRunning ? Color.primary : Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(entry.data.pomodoroIsRunning ? Color.primary.opacity(0.12) : Color.primary)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // ── Medium Widget ──
    private var mediumView: some View {
        HStack(spacing: 20) {
            // Left: Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 6)
                    .frame(width: 88, height: 88)

                Circle()
                    .trim(from: 0, to: CGFloat(progressRatio))
                    .stroke(
                        Color.primary,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 88, height: 88)

                if entry.data.pomodoroIsRunning, let target = entry.data.pomodoroTargetEndTime {
                    Text(timerInterval: Date()...Date(timeIntervalSince1970: target), countsDown: true)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.primary)
                } else {
                    Text(formattedTime)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.primary)
                }
            }

            // Right: Information and Controls
            VStack(alignment: .leading, spacing: 6) {
                Text("POMODORO")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2.5)
                    .foregroundStyle(Color.secondary)

                Text(phaseTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.primary)

                // Session Indicator Dots (4 dots)
                HStack(spacing: 6) {
                    ForEach(1...entry.data.pomodoroTotalSessions, id: \.self) { s in
                        Circle()
                            .fill(s <= entry.data.pomodoroSession ? Color.primary : Color.primary.opacity(0.18))
                            .frame(width: 6, height: 6)
                    }
                    Text("Session \(entry.data.pomodoroSession) of \(entry.data.pomodoroTotalSessions)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.bottom, 2)

                Spacer()

                // Interactive Action Buttons
                HStack(spacing: 8) {
                    Button(intent: TogglePomodoroWidgetIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: entry.data.pomodoroIsRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text(entry.data.pomodoroIsRunning ? "PAUSE" : "START")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                        }
                        .foregroundStyle(entry.data.pomodoroIsRunning ? Color.primary : Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(entry.data.pomodoroIsRunning ? Color.primary.opacity(0.12) : Color.primary)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(intent: ResetPomodoroWidgetIntent()) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.primary.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // ── Lock Screen Circular ──
    private var accessoryCircularView: some View {
        ZStack {
            Gauge(value: progressRatio) {
                Image(systemName: "hourglass")
            } currentValueLabel: {
                Text(formattedTime)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
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
