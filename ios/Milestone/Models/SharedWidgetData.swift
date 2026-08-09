import Foundation
import WidgetKit

public struct MilestoneWidgetData: Codable {
    // ── Pomodoro state ──
    public let pomodoroPhase: String        // "focus" | "shortBreak" | "longBreak"
    public let pomodoroTimeRemaining: Int   // seconds
    public let pomodoroTotalTime: Int       // seconds
    public let pomodoroIsRunning: Bool
    public let pomodoroSession: Int         // 1-4
    public let pomodoroTotalSessions: Int   // 4

    // ── Mission state ──
    public let missionTitle: String?
    public let missionTargetDate: Double?   // Unix timestamp (seconds)
    public let missionCreatedAt: Double?    // Unix timestamp (seconds)
    public let missionTodosTotal: Int
    public let missionTodosDone: Int

    // ── Meta ──
    public let lastUpdated: Double          // Unix timestamp (seconds)

    public init(
        pomodoroPhase: String = "focus",
        pomodoroTimeRemaining: Int = 1500,
        pomodoroTotalTime: Int = 1500,
        pomodoroIsRunning: Bool = false,
        pomodoroSession: Int = 1,
        pomodoroTotalSessions: Int = 4,
        missionTitle: String? = nil,
        missionTargetDate: Double? = nil,
        missionCreatedAt: Double? = nil,
        missionTodosTotal: Int = 0,
        missionTodosDone: Int = 0,
        lastUpdated: Double = Date().timeIntervalSince1970
    ) {
        self.pomodoroPhase = pomodoroPhase
        self.pomodoroTimeRemaining = pomodoroTimeRemaining
        self.pomodoroTotalTime = pomodoroTotalTime
        self.pomodoroIsRunning = pomodoroIsRunning
        self.pomodoroSession = pomodoroSession
        self.pomodoroTotalSessions = pomodoroTotalSessions
        self.missionTitle = missionTitle
        self.missionTargetDate = missionTargetDate
        self.missionCreatedAt = missionCreatedAt
        self.missionTodosTotal = missionTodosTotal
        self.missionTodosDone = missionTodosDone
        self.lastUpdated = lastUpdated
    }
}

public enum SharedWidgetStore {
    public static let suiteName = "group.com.mathurharsh.milestone"
    public static let widgetDataKey = "milestoneWidgetData"

    public static func load() -> MilestoneWidgetData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let jsonString = defaults.string(forKey: widgetDataKey),
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(MilestoneWidgetData.self, from: data)
    }

    public static func save(_ data: MilestoneWidgetData) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let encoded = try? JSONEncoder().encode(data),
           let jsonString = String(data: encoded, encoding: .utf8) {
            defaults.set(jsonString, forKey: widgetDataKey)
            defaults.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
