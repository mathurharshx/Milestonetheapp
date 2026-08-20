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
        startDate: Date,
        targetEndTime: Date,
        totalDuration: Double
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = PomodoroActivityAttributes.ContentState(
            phase: phase,
            currentSession: currentSession,
            totalSessions: totalSessions,
            startDate: startDate,
            targetEndTime: targetEndTime,
            isRunning: true,
            totalDuration: totalDuration,
            timeRemainingWhenPaused: 0
        )

        // If an active activity already exists for this app, update it instead of destroying/re-requesting
        if let existing = currentActivity, existing.activityState == .active {
            Task {
                await existing.update(.init(state: state, staleDate: targetEndTime.addingTimeInterval(60)))
            }
            return
        }

        // Clean up any stale orphaned activities from previous app runs without resetting currentActivity
        let activeActivities = Activity<PomodoroActivityAttributes>.activities.filter { $0.activityState == .active }
        if let existingActive = activeActivities.first {
            self.currentActivity = existingActive
            Task {
                await existingActive.update(.init(state: state, staleDate: targetEndTime.addingTimeInterval(60)))
            }
            return
        }

        let attributes = PomodoroActivityAttributes()
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: targetEndTime.addingTimeInterval(60)),
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
        startDate: Date,
        targetEndTime: Date,
        isRunning: Bool,
        totalDuration: Double,
        timeRemainingWhenPaused: Int = 0
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = PomodoroActivityAttributes.ContentState(
            phase: phase,
            currentSession: currentSession,
            totalSessions: totalSessions,
            startDate: startDate,
            targetEndTime: targetEndTime,
            isRunning: isRunning,
            totalDuration: totalDuration,
            timeRemainingWhenPaused: timeRemainingWhenPaused
        )

        if let activity = currentActivity, activity.activityState == .active {
            Task {
                await activity.update(.init(state: state, staleDate: targetEndTime.addingTimeInterval(60)))
            }
        } else if isRunning {
            startActivity(
                phase: phase,
                currentSession: currentSession,
                totalSessions: totalSessions,
                startDate: startDate,
                targetEndTime: targetEndTime,
                totalDuration: totalDuration
            )
        }
    }

    public func endActivity() {
        if let activity = currentActivity {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.currentActivity = nil
        }

        for act in Activity<PomodoroActivityAttributes>.activities {
            Task {
                await act.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
