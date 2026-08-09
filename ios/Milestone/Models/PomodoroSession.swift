import Foundation

public enum PomodoroPhase: String, Codable, CaseIterable {
    case focus = "focus"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"

    public var title: String {
        switch self {
        case .focus: return "FOCUS"
        case .shortBreak: return "SHORT BREAK"
        case .longBreak: return "LONG BREAK"
        }
    }

    public var message: String {
        switch self {
        case .focus: return "Stay locked in."
        case .shortBreak: return "Rest your eyes."
        case .longBreak: return "You earned this."
        }
    }

    public var defaultDuration: Int {
        switch self {
        case .focus: return 25 * 60       // 25 minutes
        case .shortBreak: return 5 * 60   // 5 minutes
        case .longBreak: return 20 * 60   // 20 minutes
        }
    }
}

public struct PomodoroState: Codable {
    public var phase: PomodoroPhase
    public var timeRemaining: Int
    public var totalTime: Int
    public var isRunning: Bool
    public var currentSession: Int
    public var totalSessions: Int
    public var isStarted: Bool

    public static let sessionsPerCycle: Int = 4

    public init(
        phase: PomodoroPhase = .focus,
        timeRemaining: Int = 25 * 60,
        totalTime: Int = 25 * 60,
        isRunning: Bool = false,
        currentSession: Int = 1,
        totalSessions: Int = 4,
        isStarted: Bool = false
    ) {
        self.phase = phase
        self.timeRemaining = timeRemaining
        self.totalTime = totalTime
        self.isRunning = isRunning
        self.currentSession = currentSession
        self.totalSessions = totalSessions
        self.isStarted = isStarted
    }

    public var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }
}
