import Foundation
import UserNotifications

@MainActor
public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let pomodoroIdentifier = "milestone.notification.pomodoro"
    private let morningIdentifier = "milestone.notification.morning"

    private override init() {
        super.init()
        center.delegate = self
    }

    // ── UNUserNotificationCenterDelegate ──
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list, .badge])
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert])
            return granted
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
            return false
        }
    }

    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // ── Pomodoro Notifications (Multi-Phase Pre-Scheduled Lock Screen Notifications) ──
    public func schedulePomodoroCycle(
        currentPhase: PomodoroPhase,
        currentSession: Int,
        totalSessions: Int,
        remainingInCurrentPhase: Int,
        focusDuration: Int,
        shortBreakDuration: Int,
        longBreakDuration: Int
    ) {
        cancelPomodoroNotifications()

        var cumulativeOffset = 0
        var phase = currentPhase
        var session = currentSession

        // Pre-schedule upcoming notifications (up to 8 phase transitions)
        for i in 0..<8 {
            let durationForThisPhase: Int
            if i == 0 {
                durationForThisPhase = remainingInCurrentPhase
            } else {
                switch phase {
                case .focus: durationForThisPhase = focusDuration
                case .shortBreak: durationForThisPhase = shortBreakDuration
                case .longBreak: durationForThisPhase = longBreakDuration
                }
            }

            cumulativeOffset += max(1, durationForThisPhase)

            // Compute next phase after this phase finishes
            let nextPhase: PomodoroPhase
            let nextSession: Int
            if phase == .focus {
                if session >= totalSessions {
                    nextPhase = .longBreak
                    nextSession = session
                } else {
                    nextPhase = .shortBreak
                    nextSession = session
                }
            } else if phase == .shortBreak {
                nextPhase = .focus
                nextSession = session + 1
            } else {
                nextPhase = .focus
                nextSession = 1
            }

            let content = UNMutableNotificationContent()
            content.sound = .default
            content.interruptionLevel = .timeSensitive // Ensures Lock Screen delivery even during Focus mode

            switch phase {
            case .focus:
                content.title = "Focus Session \(session) Complete"
                if nextPhase == .longBreak {
                    content.body = "Great work! Time for your long break."
                } else {
                    content.body = "Time for your short break."
                }
            case .shortBreak:
                content.title = "Break Complete"
                content.body = "Ready for Focus Session \(nextSession) of \(totalSessions)."
            case .longBreak:
                content.title = "Long Break Complete"
                content.body = "Cycle completed! Ready to start a new focus cycle."
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(cumulativeOffset), repeats: false)
            let identifier = "milestone.notification.pomodoro.\(i)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule pomodoro notification \(i): \(error.localizedDescription)")
                }
            }

            // Advance local state for next iteration
            phase = nextPhase
            session = nextSession
        }
    }

    public func cancelPomodoroNotifications() {
        let ids = (0..<12).map { "milestone.notification.pomodoro.\($0)" } + [pomodoroIdentifier]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    // ── Daily Morning Accountability Notification (Clean, Minimal, No Emojis) ──
    public func scheduleDailyMorningReminder(mission: Mission?, hour: Int = 9, minute: Int = 0) {
        cancelDailyMorningReminder()

        guard let mission = mission, mission.isActive else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Mission Update"
        content.sound = .default

        let daysRemaining = DateCalculations.getDaysRemaining(targetDate: mission.targetDate)
        let pendingTasks = mission.todos.filter { !$0.done }.count

        if daysRemaining == 0 {
            content.body = "Today is the target date for '\(mission.title)'."
        } else if daysRemaining == 1 {
            content.body = "1 day remaining for '\(mission.title)'."
        } else {
            content.body = "\(daysRemaining) days remaining for '\(mission.title)'."
        }

        if pendingTasks > 0 {
            content.body += " \(pendingTasks) task\(pendingTasks == 1 ? "" : "s") pending."
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: morningIdentifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule morning reminder: \(error.localizedDescription)")
            }
        }
    }

    public func cancelDailyMorningReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [morningIdentifier])
    }
}
