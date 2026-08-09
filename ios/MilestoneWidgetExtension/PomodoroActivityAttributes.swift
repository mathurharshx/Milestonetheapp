import ActivityKit
import Foundation

public struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var phase: String        // "focus", "shortBreak", "longBreak"
        public var currentSession: Int  // 1...4
        public var totalSessions: Int   // 4
        public var targetEndTime: Date
        public var isRunning: Bool
        public var totalDuration: Double
        public var timeRemainingWhenPaused: Int

        public init(
            phase: String,
            currentSession: Int,
            totalSessions: Int,
            targetEndTime: Date,
            isRunning: Bool,
            totalDuration: Double,
            timeRemainingWhenPaused: Int = 0
        ) {
            self.phase = phase
            self.currentSession = currentSession
            self.totalSessions = totalSessions
            self.targetEndTime = targetEndTime
            self.isRunning = isRunning
            self.totalDuration = totalDuration
            self.timeRemainingWhenPaused = timeRemainingWhenPaused
        }
    }

    public var sessionId: String

    public init(sessionId: String = UUID().uuidString) {
        self.sessionId = sessionId
    }
}
