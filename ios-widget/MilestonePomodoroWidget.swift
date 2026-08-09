import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct PomodoroProvider: TimelineProvider {
    func placeholder(in context: Context) -> PomodoroEntry {
        PomodoroEntry(
            date: Date(),
            phase: "focus",
            timeRemaining: 1500,
            totalTime: 1500,
            isRunning: false,
            session: 1,
            totalSessions: 4
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PomodoroEntry) -> Void) {
        let entry = entryFromData() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PomodoroEntry>) -> Void) {
        let entry = entryFromData() ?? placeholder(in: context)

        // If running, request refresh every 60 seconds for countdown accuracy
        // If paused, refresh in 15 minutes (low-frequency check)
        let refreshDate: Date
        if entry.isRunning {
            refreshDate = Calendar.current.date(byAdding: .second, value: 60, to: Date())!
        } else {
            refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func entryFromData() -> PomodoroEntry? {
        guard let data = loadWidgetData() else { return nil }
        return PomodoroEntry(
            date: Date(),
            phase: data.pomodoroPhase,
            timeRemaining: data.pomodoroTimeRemaining,
            totalTime: data.pomodoroTotalTime,
            isRunning: data.pomodoroIsRunning,
            session: data.pomodoroSession,
            totalSessions: data.pomodoroTotalSessions
        )
    }
}

// MARK: - Timeline Entry

struct PomodoroEntry: TimelineEntry {
    let date: Date
    let phase: String
    let timeRemaining: Int
    let totalTime: Int
    let isRunning: Bool
    let session: Int
    let totalSessions: Int
}

// MARK: - Widget View

struct PomodoroWidgetView: View {
    var entry: PomodoroEntry
    @Environment(\.widgetFamily) var family

    private var accentColor: Color {
        switch entry.phase {
        case "focus": return Color(red: 0.231, green: 0.51, blue: 0.965)  // #3B82F6
        case "shortBreak": return Color(red: 0.06, green: 0.78, blue: 0.82) // cyan
        case "longBreak": return Color(red: 0.56, green: 0.75, blue: 1.0)   // light blue
        default: return Color(red: 0.231, green: 0.51, blue: 0.965)
        }
    }

    private var phaseLabel: String {
        switch entry.phase {
        case "focus": return "FOCUS"
        case "shortBreak": return "SHORT BREAK"
        case "longBreak": return "LONG BREAK"
        default: return "FOCUS"
        }
    }

    private var timeString: String {
        let mins = entry.timeRemaining / 60
        let secs = entry.timeRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private var progress: Double {
        guard entry.totalTime > 0 else { return 0 }
        return Double(entry.totalTime - entry.timeRemaining) / Double(entry.totalTime)
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.039, green: 0.039, blue: 0.039) // #0a0a0a

            VStack(spacing: family == .systemSmall ? 6 : 10) {
                // Phase badge
                Text(phaseLabel)
                    .font(.system(size: family == .systemSmall ? 9 : 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(accentColor)

                // Timer
                Text(timeString)
                    .font(.system(size: family == .systemSmall ? 32 : 42, weight: .light, design: .monospaced))
                    .foregroundColor(.white)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor)
                            .frame(width: geometry.size.width * progress, height: 3)
                    }
                }
                .frame(height: 3)

                // Session dots
                HStack(spacing: 6) {
                    ForEach(1...entry.totalSessions, id: \.self) { i in
                        Circle()
                            .fill(i <= entry.session ? accentColor : Color.white.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                }

                // Status
                if entry.isRunning {
                    Text("RUNNING")
                        .font(.system(size: 8, weight: .medium))
                        .tracking(1)
                        .foregroundColor(accentColor.opacity(0.8))
                } else {
                    Text("PAUSED")
                        .font(.system(size: 8, weight: .medium))
                        .tracking(1)
                        .foregroundColor(Color.white.opacity(0.4))
                }
            }
            .padding(family == .systemSmall ? 12 : 16)
        }
    }
}

// MARK: - Widget Configuration

struct MilestonePomodoroWidget: Widget {
    let kind: String = "MilestonePomodoroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroProvider()) { entry in
            PomodoroWidgetView(entry: entry)
        }
        .configurationDisplayName("Pomodoro Timer")
        .description("Track your focus sessions at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
