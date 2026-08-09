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

    public var progress: Double {
        guard totalTime > 0 else { return 0 }
        let elapsed = max(0, totalTime - timeRemaining)
        return Double(elapsed) / Double(totalTime)
    }

    public init() {
        self.totalTime = phase.defaultDuration
        self.timeRemaining = self.totalTime
    }

    public func start() {
        guard timeRemaining > 0 else { return }
        isStarted = true
        isRunning = true
        let target = Date().addingTimeInterval(TimeInterval(timeRemaining))
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

        PomodoroActivityManager.shared.startActivity(
            phase: phase.rawValue,
            currentSession: currentSession,
            totalSessions: totalSessions,
            targetEndTime: target,
            totalDuration: Double(totalTime)
        )
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

        PomodoroActivityManager.shared.updateActivity(
            phase: phase.rawValue,
            currentSession: currentSession,
            totalSessions: totalSessions,
            targetEndTime: targetEndTime ?? Date(),
            isRunning: false,
            totalDuration: Double(totalTime),
            timeRemainingWhenPaused: timeRemaining
        )
    }

    public func reset() {
        isRunning = false
        isStarted = false
        timerTask?.cancel()
        timerTask = nil
        phase = .focus
        currentSession = 1
        totalTime = phase.defaultDuration
        timeRemaining = totalTime
        targetEndTime = nil
        syncToWidget()

        PomodoroActivityManager.shared.endActivity()
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
        self.totalTime = nextPhase.defaultDuration
        self.timeRemaining = self.totalTime

        // Auto-start next phase
        self.isRunning = true
        let target = Date().addingTimeInterval(TimeInterval(self.totalTime))
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

        PomodoroActivityManager.shared.startActivity(
            phase: phase.rawValue,
            currentSession: currentSession,
            totalSessions: totalSessions,
            targetEndTime: target,
            totalDuration: Double(totalTime)
        )
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
            // After long break, reset cycle to session 1 focus
            return (.focus, 1)
        }
    }

    public var nextPhaseLabel: String {
        switch phase {
        case .focus:
            return currentSession >= totalSessions ? "Long Break  ·  20m" : "Short Break  ·  5m"
        case .shortBreak:
            return "Focus \(currentSession + 1) of \(totalSessions)  ·  25m"
        case .longBreak:
            return "Focus 1 of \(totalSessions)  ·  25m"
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
