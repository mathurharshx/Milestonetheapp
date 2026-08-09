import SwiftUI
import Observation

@MainActor
@Observable
public final class PomodoroStore {
    public var phase: PomodoroPhase = .focus
    public var timeRemaining: Int = 25 * 60
    public var totalTime: Int = 25 * 60
    public var isRunning: Bool = false
    public var currentSession: Int = 1
    public var totalSessions: Int = 4
    public var isStarted: Bool = false

    private var timerTask: Task<Void, Never>?
    private var targetEndTime: Date?
    private var sessionStartDate: Date = Date()

    public var progress: Double {
        guard totalTime > 0 else { return 0 }
        let elapsed = max(0, totalTime - timeRemaining)
        return Double(elapsed) / Double(totalTime)
    }

    public init() {
        let initialDuration = durationForPhase(.focus)
        self.totalTime = initialDuration
        self.timeRemaining = initialDuration
    }

    private func durationForPhase(_ p: PomodoroPhase) -> Int {
        switch p {
        case .focus:
            let mins = UserDefaults.standard.integer(forKey: "milestone:focusDuration")
            return (mins > 0 ? mins : 25) * 60
        case .shortBreak:
            let mins = UserDefaults.standard.integer(forKey: "milestone:shortBreakDuration")
            return (mins > 0 ? mins : 5) * 60
        case .longBreak:
            let mins = UserDefaults.standard.integer(forKey: "milestone:longBreakDuration")
            return (mins > 0 ? mins : 20) * 60
        }
    }

    public func reloadDurationsIfIdle() {
        guard !isRunning && !isStarted else { return }
        let newDuration = durationForPhase(phase)
        self.totalTime = newDuration
        self.timeRemaining = newDuration
    }

    public func start() {
        guard timeRemaining > 0 else { return }
        isStarted = true
        isRunning = true
        let now = Date()
        sessionStartDate = now
        let target = now.addingTimeInterval(TimeInterval(timeRemaining))
        targetEndTime = target
        
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
                guard let self = self, self.isRunning else { break }
                self.tick()
            }
        }
        syncToWidget()

        // 1. Start Dynamic Island / Lock Screen Activity
        PomodoroActivityManager.shared.startActivity(
            phase: phase.rawValue,
            currentSession: currentSession,
            totalSessions: totalSessions,
            startDate: sessionStartDate,
            targetEndTime: target,
            totalDuration: Double(totalTime)
        )

        // 2. Schedule Clean Background Local Notification
        let notificationsEnabled = UserDefaults.standard.object(forKey: "milestone:timerNotificationsEnabled") as? Bool ?? true
        if notificationsEnabled {
            NotificationManager.shared.schedulePomodoroNotification(
                phase: phase,
                seconds: timeRemaining,
                nextPhaseLabel: nextPhaseLabel
            )
        }
    }

    public func pause() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        if let target = targetEndTime {
            let remaining = max(0, Int(ceil(target.timeIntervalSinceNow)))
            timeRemaining = remaining
        }
        syncToWidget()

        // 1. Update Dynamic Island
        PomodoroActivityManager.shared.updateActivity(
            phase: phase.rawValue,
            currentSession: currentSession,
            totalSessions: totalSessions,
            startDate: sessionStartDate,
            targetEndTime: targetEndTime ?? Date(),
            isRunning: false,
            totalDuration: Double(totalTime),
            timeRemainingWhenPaused: timeRemaining
        )

        // 2. Cancel Notification while paused
        NotificationManager.shared.cancelPomodoroNotifications()
    }

    public func reset() {
        isRunning = false
        isStarted = false
        timerTask?.cancel()
        timerTask = nil
        phase = .focus
        currentSession = 1
        totalTime = durationForPhase(.focus)
        timeRemaining = totalTime
        targetEndTime = nil
        syncToWidget()

        // 1. End Dynamic Island
        PomodoroActivityManager.shared.endActivity()

        // 2. Cancel Notification
        NotificationManager.shared.cancelPomodoroNotifications()
    }

    private func tick() {
        guard isRunning, let target = targetEndTime else { return }
        let diff = target.timeIntervalSinceNow
        let remaining = max(0, Int(ceil(diff)))

        if remaining != timeRemaining {
            timeRemaining = remaining
        }

        if diff <= 0 {
            timerTask?.cancel()
            timerTask = nil
            HapticsManager.shared.notification(.success)
            advanceToNextPhase()
        }
    }

    public func advanceToNextPhase() {
        let (nextPhase, nextSession) = getNextPhase(current: phase, session: currentSession)
        self.phase = nextPhase
        self.currentSession = nextSession
        self.totalTime = durationForPhase(nextPhase)
        self.timeRemaining = self.totalTime

        // Auto-start next phase
        self.isRunning = true
        let now = Date()
        self.sessionStartDate = now
        let target = now.addingTimeInterval(TimeInterval(self.totalTime))
        self.targetEndTime = target
        
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard let self = self, self.isRunning else { break }
                self.tick()
            }
        }
        syncToWidget()

        // 1. Dynamic Island Activity for new phase
        PomodoroActivityManager.shared.startActivity(
            phase: phase.rawValue,
            currentSession: currentSession,
            totalSessions: totalSessions,
            startDate: self.sessionStartDate,
            targetEndTime: target,
            totalDuration: Double(totalTime)
        )

        // 2. Background Notification for new phase
        let notificationsEnabled = UserDefaults.standard.object(forKey: "milestone:timerNotificationsEnabled") as? Bool ?? true
        if notificationsEnabled {
            NotificationManager.shared.schedulePomodoroNotification(
                phase: phase,
                seconds: timeRemaining,
                nextPhaseLabel: nextPhaseLabel
            )
        }
    }

    private func getNextPhase(current: PomodoroPhase, session: Int) -> (PomodoroPhase, Int) {
        if current == .focus {
            if session >= totalSessions {
                return (.longBreak, session)
            } else {
                return (.shortBreak, session)
            }
        } else if current == .shortBreak {
            return (.focus, session + 1)
        } else {
            return (.focus, 1)
        }
    }

    public var nextPhaseLabel: String {
        switch phase {
        case .focus:
            let breakMins = durationForPhase(currentSession >= totalSessions ? .longBreak : .shortBreak) / 60
            return currentSession >= totalSessions ? "Long Break (\(breakMins)m)" : "Short Break (\(breakMins)m)"
        case .shortBreak:
            let focusMins = durationForPhase(.focus) / 60
            return "Focus \(currentSession + 1) of \(totalSessions) (\(focusMins)m)"
        case .longBreak:
            let focusMins = durationForPhase(.focus) / 60
            return "Focus 1 of \(totalSessions) (\(focusMins)m)"
        }
    }

    public func syncToWidget() {
        let existing = SharedWidgetStore.load() ?? MilestoneWidgetData()

        let updated = MilestoneWidgetData(
            pomodoroPhase: phase.rawValue,
            pomodoroTimeRemaining: timeRemaining,
            pomodoroTotalTime: totalTime,
            pomodoroIsRunning: isRunning,
            pomodoroSession: currentSession,
            pomodoroTotalSessions: totalSessions,
            missionTitle: existing.missionTitle,
            missionTargetDate: existing.missionTargetDate,
            missionCreatedAt: existing.missionCreatedAt,
            missionTodosTotal: existing.missionTodosTotal,
            missionTodosDone: existing.missionTodosDone,
            lastUpdated: Date().timeIntervalSince1970
        )
        SharedWidgetStore.save(updated)
    }
}
