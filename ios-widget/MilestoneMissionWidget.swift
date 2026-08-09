import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct MissionProvider: TimelineProvider {
    func placeholder(in context: Context) -> MissionEntry {
        MissionEntry(
            date: Date(),
            title: "My Mission",
            targetDate: Date().addingTimeInterval(86400 * 30),
            daysRemaining: 30,
            todosTotal: 5,
            todosDone: 2,
            hasMission: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MissionEntry) -> Void) {
        let entry = entryFromData() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MissionEntry>) -> Void) {
        let entry = entryFromData() ?? MissionEntry(
            date: Date(),
            title: nil,
            targetDate: nil,
            daysRemaining: 0,
            todosTotal: 0,
            todosDone: 0,
            hasMission: false
        )

        // Refresh every 30 minutes for mission countdown
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func entryFromData() -> MissionEntry? {
        guard let data = loadWidgetData(),
              let title = data.missionTitle,
              let targetTs = data.missionTargetDate else {
            return nil
        }

        let targetDate = Date(timeIntervalSince1970: targetTs)
        let now = Date()
        let daysRemaining = max(0, Calendar.current.dateComponents([.day], from: now, to: targetDate).day ?? 0)

        return MissionEntry(
            date: now,
            title: title,
            targetDate: targetDate,
            daysRemaining: daysRemaining,
            todosTotal: data.missionTodosTotal,
            todosDone: data.missionTodosDone,
            hasMission: true
        )
    }
}

// MARK: - Timeline Entry

struct MissionEntry: TimelineEntry {
    let date: Date
    let title: String?
    let targetDate: Date?
    let daysRemaining: Int
    let todosTotal: Int
    let todosDone: Int
    let hasMission: Bool
}

// MARK: - Widget View

struct MissionWidgetView: View {
    var entry: MissionEntry
    @Environment(\.widgetFamily) var family

    private let accentBlue = Color(red: 0.231, green: 0.51, blue: 0.965) // #3B82F6

    var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.039) // #0a0a0a

            if entry.hasMission, let title = entry.title {
                VStack(spacing: family == .systemSmall ? 6 : 10) {
                    // Mission title
                    Text(title)
                        .font(.system(size: family == .systemSmall ? 11 : 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)

                    // Days remaining - hero number
                    Text("\(entry.daysRemaining)")
                        .font(.system(size: family == .systemSmall ? 40 : 52, weight: .light))
                        .foregroundColor(.white)

                    Text("days left")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.4))

                    // Todos progress (if any)
                    if entry.todosTotal > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(accentBlue)
                            Text("\(entry.todosDone)/\(entry.todosTotal)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(family == .systemSmall ? 12 : 16)
            } else {
                // No active mission
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.2))
                    Text("No active mission")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }
}

// MARK: - Widget Configuration

struct MilestoneMissionWidget: Widget {
    let kind: String = "MilestoneMissionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MissionProvider()) { entry in
            MissionWidgetView(entry: entry)
        }
        .configurationDisplayName("Mission Countdown")
        .description("Track your mission deadline and task progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
