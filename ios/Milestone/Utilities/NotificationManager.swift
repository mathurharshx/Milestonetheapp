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

    // ── Pomodoro Notifications (Time Sensitive, Crisp & Lock Screen Ready) ──
    public func schedulePomodoroNotification(phase: PomodoroPhase, seconds: Int, nextPhaseLabel: String) {
        guard seconds > 0 else { return }

        // Cancel any pending timer notification first
        cancelPomodoroNotifications()

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.interruptionLevel = .timeSensitive // Time sensitive for Lock Screen delivery

        switch phase {
        case .focus:
            content.title = "Focus Session Complete"
            content.body = "Time for your \(nextPhaseLabel.lowercased())."
        case .shortBreak:
            content.title = "Break Complete"
            content.body = "Ready to start your next focus session."
        case .longBreak:
            content.title = "Extended Break Complete"
            content.body = "Ready to begin a new focus cycle."
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: pomodoroIdentifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule pomodoro notification: \(error.localizedDescription)")
            }
        }
    }

    public func cancelPomodoroNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: [pomodoroIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [pomodoroIdentifier])
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
