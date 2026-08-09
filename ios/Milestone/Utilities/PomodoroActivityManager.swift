import ActivityKit
import Foundation

@MainActor
public final class PomodoroActivityManager {
    public static let shared = PomodoroActivityManager()

    private var currentActivity: Activity<PomodoroActivityAttributes>?

    private init() {}

    public func startActivity(
        phase: String,
        currentSession: Int,
        totalSessions: Int,
        targetEndTime: Date,
        totalDuration: Double
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activities first
        endActivity()

        let attributes = PomodoroActivityAttributes()
        let initialContentState = PomodoroActivityAttributes.ContentState(
            phase: phase,
            currentSession: currentSession,
            totalSessions: totalSessions,
            targetEndTime: targetEndTime,
            isRunning: true,
            totalDuration: totalDuration,
            timeRemainingWhenPaused: 0
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: targetEndTime.addingTimeInterval(60)),
                pushType: nil
            )
            self.currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    public func updateActivity(
        phase: String,
        currentSession: Int,
        totalSessions: Int,
        targetEndTime: Date,
        isRunning: Bool,
        totalDuration: Double,
        timeRemainingWhenPaused: Int = 0
    ) {
        guard let activity = currentActivity else {
            // If activity was killed, re-request if running
            if isRunning {
                startActivity(
                    phase: phase,
                    currentSession: currentSession,
                    totalSessions: totalSessions,
                    targetEndTime: targetEndTime,
                    totalDuration: totalDuration
                )
            }
            return
        }

        let updatedContentState = PomodoroActivityAttributes.ContentState(
            phase: phase,
            currentSession: currentSession,
            totalSessions: totalSessions,
            targetEndTime: targetEndTime,
            isRunning: isRunning,
            totalDuration: totalDuration,
            timeRemainingWhenPaused: timeRemainingWhenPaused
        )

        Task {
            await activity.update(
                .init(state: updatedContentState, staleDate: targetEndTime.addingTimeInterval(60))
            )
        }
    }

    public func endActivity() {
        guard let activity = currentActivity else {
            for act in Activity<PomodoroActivityAttributes>.activities {
                Task {
                    await act.end(nil, dismissalPolicy: .immediate)
                }
            }
            return
        }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
    }
}
