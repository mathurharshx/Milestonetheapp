import Foundation
import UserNotifications

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
        // Clean presentation without jarring main thread banner collision
        completionHandler([.sound, .list, .badge])
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

    // ── Ultra-Clean 2-Step Pomodoro Notifications (Current + Next Phase Only) ──
    public func schedulePomodoroNotification(
        currentPhase: PomodoroPhase,
        remainingSeconds: Int,
        nextPhase: PomodoroPhase,
        nextPhaseDuration: Int,
        currentSession: Int,
        totalSessions: Int
    ) {
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            self.cancelPomodoroNotificationsInternal()

            guard remainingSeconds > 0 else { return }

            // 1. Current Phase End Notification
            let content1 = UNMutableNotificationContent()
            content1.sound = .default
            content1.interruptionLevel = .timeSensitive

            switch currentPhase {
            case .focus:
                content1.title = "Focus Session \(currentSession) Complete"
                content1.body = nextPhase == .longBreak ? "Great work! Time for your long break." : "Time for your short break."
            case .shortBreak:
                content1.title = "Break Complete"
                content1.body = "Ready for Focus Session \(min(currentSession + 1, totalSessions)) of \(totalSessions)."
            case .longBreak:
                content1.title = "Long Break Complete"
                content1.body = "Cycle complete! Ready to start a new focus cycle."
            }

            let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remainingSeconds), repeats: false)
            let req1 = UNNotificationRequest(identifier: "milestone.notification.pomodoro.current", content: content1, trigger: trigger1)
            self.center.add(req1)

            // 2. Pre-Scheduled Next Phase Backup Notification
            if nextPhaseDuration > 0 {
                let content2 = UNMutableNotificationContent()
                content2.sound = .default
                content2.interruptionLevel = .timeSensitive

                switch nextPhase {
                case .focus:
                    content2.title = "Focus Session Complete"
                    content2.body = "Time for your break."
                case .shortBreak:
                    content2.title = "Break Complete"
                    content2.body = "Time to start focus session."
                case .longBreak:
                    content2.title = "Long Break Complete"
                    content2.body = "Ready to start a new cycle."
                }

                let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remainingSeconds + nextPhaseDuration), repeats: false)
                let req2 = UNNotificationRequest(identifier: "milestone.notification.pomodoro.next", content: content2, trigger: trigger2)
                self.center.add(req2)
            }
        }
    }

    public func cancelPomodoroNotifications() {
        Task.detached(priority: .utility) { [weak self] in
            self?.cancelPomodoroNotificationsInternal()
        }
    }

    private func cancelPomodoroNotificationsInternal() {
        let ids = ["milestone.notification.pomodoro.current", "milestone.notification.pomodoro.next", pomodoroIdentifier]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    // ── Daily Morning Accountability Notification ──
    public func scheduleDailyMorningReminder(mission: Mission?, hour: Int = 9, minute: Int = 0) {
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            self.cancelDailyMorningReminderInternal()

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
            let request = UNNotificationRequest(identifier: self.morningIdentifier, content: content, trigger: trigger)

            self.center.add(request) { error in
                if let error = error {
                    print("Failed to schedule morning reminder: \(error.localizedDescription)")
                }
            }
        }
    }

    public func cancelDailyMorningReminder() {
        Task.detached(priority: .utility) { [weak self] in
            self?.cancelDailyMorningReminderInternal()
        }
    }

    private func cancelDailyMorningReminderInternal() {
        center.removePendingNotificationRequests(withIdentifiers: [morningIdentifier])
    }
}
