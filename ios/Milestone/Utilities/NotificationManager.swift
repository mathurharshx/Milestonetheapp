import Foundation
import UserNotifications

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let pomodoroIdentifier = "milestone.notification.pomodoro"
    private let morningIdentifier = "milestone.notification.morning"
    private let deadlineIdentifier = "milestone.notification.deadline"

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
        // When app is open in foreground, suppress notification banner/sound since built-in audio handles it
        completionHandler([])
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
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
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

    // ── Permanent Lock Screen Notifications (Never Disappear) ──
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
            self.cancelPendingPomodoroRequestsInternal()

            guard remainingSeconds > 0 else { return }

            let timestamp = Int(Date().timeIntervalSince1970)

            // 1. Current Phase End Notification (Unique ID so it stays permanently on Lock Screen)
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
            let req1 = UNNotificationRequest(identifier: "milestone.notification.pomodoro.\(timestamp).current", content: content1, trigger: trigger1)
            try? await self.center.add(req1)

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
                let req2 = UNNotificationRequest(identifier: "milestone.notification.pomodoro.\(timestamp).next", content: content2, trigger: trigger2)
                try? await self.center.add(req2)
            }
        }
    }

    public func cancelPomodoroNotifications() {
        Task.detached(priority: .utility) { [weak self] in
            self?.cancelPendingPomodoroRequestsInternal()
        }
    }

    private func cancelPendingPomodoroRequestsInternal() {
        center.getPendingNotificationRequests { [weak self] requests in
            let pendingIds = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("milestone.notification.pomodoro.") }
            self?.center.removePendingNotificationRequests(withIdentifiers: pendingIds)
        }
    }

    // ── Daily Morning Accountability Notification (Pre-scheduled for next 7 mornings) ──
    public func scheduleDailyMorningReminder(mission: Mission?, hour: Int = 9, minute: Int = 0) {
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            self.cancelDailyMorningReminderInternal()

            guard let mission = mission, mission.isActive else { return }

            let calendar = Calendar.current
            let now = Date()
            let pendingTasks = mission.todos.filter { !$0.done }.count

            // Schedule discrete alerts for the next 7 mornings so counts never freeze
            for dayOffset in 0..<7 {
                guard let targetMorning = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                var components = calendar.dateComponents([.year, .month, .day], from: targetMorning)
                components.hour = hour
                components.minute = minute
                components.second = 0

                guard let triggerDate = calendar.date(from: components), triggerDate > now else {
                    continue
                }

                let daysRemaining = DateCalculations.differenceInDays(from: triggerDate, to: mission.targetDate)
                guard daysRemaining >= 0 else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Daily Mission Update"
                content.sound = .default

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

                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(self.morningIdentifier).\(dayOffset)",
                    content: content,
                    trigger: trigger
                )

                try? await self.center.add(request)
            }
        }
    }

    public func cancelDailyMorningReminder() {
        Task.detached(priority: .utility) { [weak self] in
            self?.cancelDailyMorningReminderInternal()
        }
    }

    private func cancelDailyMorningReminderInternal() {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(self.morningIdentifier) }
            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    // ── Mission Target Deadline Reached Notification ──
    public func scheduleMissionDeadlineNotification(mission: Mission?) {
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            self.cancelMissionDeadlineNotificationInternal()

            guard let mission = mission, mission.isActive else { return }

            let targetDate = mission.targetDate
            let timeInterval = targetDate.timeIntervalSince(Date())

            // Only schedule if the target deadline is in the future
            guard timeInterval > 0 else { return }

            let content = UNMutableNotificationContent()
            content.title = "Mission Target Date Reached"
            content.body = "Time is up for '\(mission.title)'! Open Milestone to review and mark it accomplished."
            content.sound = .default
            content.interruptionLevel = .timeSensitive

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: self.deadlineIdentifier, content: content, trigger: trigger)

            do {
                try await self.center.add(request)
            } catch {
                print("Failed to schedule mission deadline notification: \(error.localizedDescription)")
            }
        }
    }

    public func cancelMissionDeadlineNotification() {
        Task.detached(priority: .utility) { [weak self] in
            self?.cancelMissionDeadlineNotificationInternal()
        }
    }

    private func cancelMissionDeadlineNotificationInternal() {
        center.removePendingNotificationRequests(withIdentifiers: [deadlineIdentifier])
    }
}
