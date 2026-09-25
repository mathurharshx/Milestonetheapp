import Foundation
import SwiftUI
import WidgetKit

public struct MissionWidgetPayload: Codable {
    public var title: String
    public var targetDate: Double
    public var createdAt: Double
    public var category: String       // "work" | "personal"
    public var todosTotal: Int
    public var todosDone: Int
    public var topPendingTaskText: String?
    public var topPendingTaskId: String?

    public init(
        title: String,
        targetDate: Double,
        createdAt: Double,
        category: String = "work",
        todosTotal: Int = 0,
        todosDone: Int = 0,
        topPendingTaskText: String? = nil,
        topPendingTaskId: String? = nil
    ) {
        self.title = title
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.category = category
        self.todosTotal = todosTotal
        self.todosDone = todosDone
        self.topPendingTaskText = topPendingTaskText
        self.topPendingTaskId = topPendingTaskId
    }
}

public struct MilestoneWidgetData: Codable {
    // ── Theme State (Default Dark Mode) ──
    public var isDarkMode: Bool

    // ── Pomodoro state ──
    public var pomodoroPhase: String        // "focus" | "shortBreak" | "longBreak"
    public var pomodoroTimeRemaining: Int   // seconds
    public var pomodoroTotalTime: Int       // seconds
    public var pomodoroIsRunning: Bool
    public var pomodoroSession: Int         // 1-4
    public var pomodoroTotalSessions: Int   // 4
    public var pomodoroTargetEndTime: Double? // Unix timestamp (seconds)

    // ── Mission state (Active Pillar) ──
    public var missionTitle: String?
    public var missionTargetDate: Double?   // Unix timestamp (seconds)
    public var missionCreatedAt: Double?    // Unix timestamp (seconds)
    public var missionCategory: String?     // "work" | "personal"
    public var missionTodosTotal: Int
    public var missionTodosDone: Int
    public var topPendingTaskText: String?
    public var topPendingTaskId: String?

    // ── Dual-Pillar Flagship Payload (Work & Personal) ──
    public var workMissionPayload: MissionWidgetPayload?
    public var personalMissionPayload: MissionWidgetPayload?

    // ── Momentum & Habit state ──
    public var focusStreak: Int             // e.g. 5
    public var todayFocusMinutes: Int       // e.g. 75
    public var weeklyFocusLevels: [Int]     // 7 items: 0=none, 1=light, 2=medium, 3=heavy
    public var quoteText: String?
    public var quoteAuthor: String?

    // ── Meta ──
    public var lastUpdated: Double          // Unix timestamp (seconds)

    public init(
        isDarkMode: Bool = true,
        pomodoroPhase: String = "focus",
        pomodoroTimeRemaining: Int = 1500,
        pomodoroTotalTime: Int = 1500,
        pomodoroIsRunning: Bool = false,
        pomodoroSession: Int = 1,
        pomodoroTotalSessions: Int = 4,
        pomodoroTargetEndTime: Double? = nil,
        missionTitle: String? = nil,
        missionTargetDate: Double? = nil,
        missionCreatedAt: Double? = nil,
        missionCategory: String? = "work",
        missionTodosTotal: Int = 0,
        missionTodosDone: Int = 0,
        topPendingTaskText: String? = nil,
        topPendingTaskId: String? = nil,
        workMissionPayload: MissionWidgetPayload? = nil,
        personalMissionPayload: MissionWidgetPayload? = nil,
        focusStreak: Int = 1,
        todayFocusMinutes: Int = 25,
        weeklyFocusLevels: [Int] = [1, 2, 3, 2, 3, 1, 2],
        quoteText: String? = "Discipline is destiny.",
        quoteAuthor: String? = "Marcus Aurelius",
        lastUpdated: Double = Date().timeIntervalSince1970
    ) {
        self.isDarkMode = isDarkMode
        self.pomodoroPhase = pomodoroPhase
        self.pomodoroTimeRemaining = pomodoroTimeRemaining
        self.pomodoroTotalTime = pomodoroTotalTime
        self.pomodoroIsRunning = pomodoroIsRunning
        self.pomodoroSession = pomodoroSession
        self.pomodoroTotalSessions = pomodoroTotalSessions
        self.pomodoroTargetEndTime = pomodoroTargetEndTime
        self.missionTitle = missionTitle
        self.missionTargetDate = missionTargetDate
        self.missionCreatedAt = missionCreatedAt
        self.missionCategory = missionCategory
        self.missionTodosTotal = missionTodosTotal
        self.missionTodosDone = missionTodosDone
        self.topPendingTaskText = topPendingTaskText
        self.topPendingTaskId = topPendingTaskId
        self.workMissionPayload = workMissionPayload
        self.personalMissionPayload = personalMissionPayload
        self.focusStreak = focusStreak
        self.todayFocusMinutes = todayFocusMinutes
        self.weeklyFocusLevels = weeklyFocusLevels
        self.quoteText = quoteText
        self.quoteAuthor = quoteAuthor
        self.lastUpdated = lastUpdated
    }
}

// ── Shared Color Palette Helper for Widgets ──
extension MilestoneWidgetData {
    public var backgroundColor: Color {
        isDarkMode ? Color(red: 0x0A/255.0, green: 0x0A/255.0, blue: 0x0A/255.0) : Color(red: 0xF2/255.0, green: 0xF2/255.0, blue: 0xF7/255.0)
    }

    public var surfaceColor: Color {
        isDarkMode ? Color(red: 0x14/255.0, green: 0x14/255.0, blue: 0x14/255.0) : Color(red: 0xE5/255.0, green: 0xE5/255.0, blue: 0xEA/255.0)
    }

    public var textPrimaryColor: Color {
        isDarkMode ? Color(red: 0xFA/255.0, green: 0xFA/255.0, blue: 0xFA/255.0) : Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0)
    }

    public var textSecondaryColor: Color {
        textPrimaryColor.opacity(0.55)
    }

    public var textTertiaryColor: Color {
        textPrimaryColor.opacity(0.30)
    }

    public var trackColor: Color {
        isDarkMode ? Color(red: 0x22/255.0, green: 0x22/255.0, blue: 0x22/255.0) : Color(red: 0xD1/255.0, green: 0xD1/255.0, blue: 0xD6/255.0)
    }

    public var accentColor: Color {
        isDarkMode ? Color(red: 0xFA/255.0, green: 0xFA/255.0, blue: 0xFA/255.0) : Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0)
    }

    public var activeGlowColor: Color {
        isDarkMode ? Color(red: 0xFA/255.0, green: 0xFA/255.0, blue: 0xFA/255.0) : Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0)
    }
}

public enum SharedWidgetStore {
    public static let suiteName = "group.com.mathurharsh.milestonetheapp"
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
