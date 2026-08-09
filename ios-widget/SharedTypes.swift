import Foundation

/// Shared data model between React Native and WidgetKit.
/// This struct mirrors the JSON written by the RN side via WidgetBridge.
struct MilestoneWidgetData: Codable {
    // ── Pomodoro state ──
    let pomodoroPhase: String        // "focus" | "shortBreak" | "longBreak"
    let pomodoroTimeRemaining: Int   // seconds
    let pomodoroTotalTime: Int       // seconds
    let pomodoroIsRunning: Bool
    let pomodoroSession: Int         // 1-4
    let pomodoroTotalSessions: Int   // 4

    // ── Mission state ──
    let missionTitle: String?
    let missionTargetDate: Double?   // Unix timestamp (seconds)
    let missionCreatedAt: Double?    // Unix timestamp (seconds)
    let missionTodosTotal: Int
    let missionTodosDone: Int

    // ── Meta ──
    let lastUpdated: Double          // Unix timestamp (seconds)
}

/// Keys used in shared UserDefaults
enum SharedKeys {
    static let suiteName = "group.com.mathurharsh.milestone"
    static let widgetData = "milestoneWidgetData"
}

/// Load widget data from shared UserDefaults
func loadWidgetData() -> MilestoneWidgetData? {
    guard let defaults = UserDefaults(suiteName: SharedKeys.suiteName),
          let jsonString = defaults.string(forKey: SharedKeys.widgetData),
          let data = jsonString.data(using: .utf8) else {
        return nil
    }
    return try? JSONDecoder().decode(MilestoneWidgetData.self, from: data)
}
