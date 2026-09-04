import Foundation
import SwiftUI

public enum PacingStatus: String, CaseIterable, Sendable {
    case hyperPacing
    case onTrack
    case slightDrift
    case criticalDrift
    case calibrating

    public var title: String {
        switch self {
        case .hyperPacing: return "HYPER-PACING"
        case .onTrack: return "ON TRACK"
        case .slightDrift: return "SLIGHT DRIFT"
        case .criticalDrift: return "CRITICAL DRIFT"
        case .calibrating: return "CALIBRATING"
        }
    }

    public var subtitle: String {
        switch self {
        case .hyperPacing: return "Pacing significantly ahead of your target deadline."
        case .onTrack: return "Execution speed is perfectly synchronized with timeline."
        case .slightDrift: return "Completion velocity is lagging behind target."
        case .criticalDrift: return "Timeline slipping. Urgent focus sprints required."
        case .calibrating: return "Establishing baseline cadence for active mission."
        }
    }

    public var badgeSymbol: String {
        switch self {
        case .hyperPacing: return "bolt.fill"
        case .onTrack: return "checkmark.seal.fill"
        case .slightDrift: return "exclamationmark.triangle.fill"
        case .criticalDrift: return "flame.fill"
        case .calibrating: return "gauge.with.needle"
        }
    }

    public var tintColor: Color {
        switch self {
        case .hyperPacing: return Color(red: 0.32, green: 0.72, blue: 0.53) // Emerald
        case .onTrack: return Color(red: 0.88, green: 0.76, blue: 0.44) // Gold / Accent
        case .slightDrift: return Color(red: 0.90, green: 0.62, blue: 0.32) // Amber
        case .criticalDrift: return Color(red: 0.92, green: 0.35, blue: 0.35) // Coral red
        case .calibrating: return Color(white: 0.60)
        }
    }
}

public struct DailyFocusCadence: Identifiable, Equatable, Sendable {
    public var id: String { dayKey }
    public let dayKey: String
    public let dayLabel: String
    public let minutes: Int
    public let isToday: Bool

    public init(dayKey: String, dayLabel: String, minutes: Int, isToday: Bool) {
        self.dayKey = dayKey
        self.dayLabel = dayLabel
        self.minutes = minutes
        self.isToday = isToday
    }
}

public struct VelocityReport: Equatable, Sendable {
    public let velocity: Double
    public let status: PacingStatus
    public let driftDays: Double
    public let driftHours: Int
    public let projectedCompletionDate: Date
    public let taskProgressRatio: Double
    public let timeElapsedRatio: Double
    public let completedTasksCount: Int
    public let totalTasksCount: Int
    public let weeklyCadence: [DailyFocusCadence]
    public let streakCount: Int

    public var formattedVelocity: String {
        if status == .calibrating {
            return "1.00x"
        }
        return String(format: "%.2fx", velocity)
    }

    public var formattedDriftText: String {
        if abs(driftHours) < 1 {
            return "Exact on-schedule"
        } else if driftHours < 0 {
            let aheadHours = abs(driftHours)
            if aheadHours >= 24 {
                let days = aheadHours / 24
                let remainingH = aheadHours % 24
                return remainingH > 0 ? "\(days)d \(remainingH)h ahead" : "\(days)d ahead"
            }
            return "\(aheadHours)h ahead"
        } else {
            if driftHours >= 24 {
                let days = driftHours / 24
                let remainingH = driftHours % 24
                return remainingH > 0 ? "+\(days)d \(remainingH)h drift" : "+\(days)d drift"
            }
            return "+\(driftHours)h drift"
        }
    }
}

public enum VelocityCalculator {
    public static func calculateReport(
        mission: Mission,
        archivedMissions: [Mission] = []
    ) -> VelocityReport {
        let now = Date()
        let totalTasks = mission.todos.count
        let completedTasks = mission.todos.filter { $0.done }.count

        let totalDuration = max(60.0, mission.targetDate.timeIntervalSince(mission.createdAt))
        let elapsedSeconds = max(0.0, now.timeIntervalSince(mission.createdAt))
        let timeRatio = min(1.0, max(0.001, elapsedSeconds / totalDuration))

        // 1. Task progress ratio
        let taskRatio: Double
        if totalTasks == 0 {
            taskRatio = 0.0
        } else {
            taskRatio = Double(completedTasks) / Double(totalTasks)
        }

        // 2. Velocity computation: V = TaskProgress / TimeProgress
        let rawVelocity: Double
        let status: PacingStatus

        if totalTasks == 0 || (elapsedSeconds < 1800 && completedTasks == 0) {
            rawVelocity = 1.0
            status = .calibrating
        } else if completedTasks == 0 {
            // No tasks completed yet but time is passing
            if timeRatio > 0.40 {
                rawVelocity = 0.45
                status = .criticalDrift
            } else if timeRatio > 0.15 {
                rawVelocity = 0.70
                status = .slightDrift
            } else {
                rawVelocity = 0.95
                status = .onTrack
            }
        } else if taskRatio >= 1.0 {
            rawVelocity = max(1.5, 1.0 / timeRatio)
            status = .hyperPacing
        } else {
            let computed = taskRatio / timeRatio
            rawVelocity = min(4.0, max(0.1, computed))

            if rawVelocity >= 1.15 {
                status = .hyperPacing
            } else if rawVelocity >= 0.90 {
                status = .onTrack
            } else if rawVelocity >= 0.65 {
                status = .slightDrift
            } else {
                status = .criticalDrift
            }
        }

        // 3. Projected Completion & Drift
        let effectiveVelocity = max(0.15, rawVelocity)
        let estimatedTotalDuration = totalDuration / effectiveVelocity
        let projectedDate = mission.createdAt.addingTimeInterval(estimatedTotalDuration)
        let driftSeconds = projectedDate.timeIntervalSince(mission.targetDate)
        let driftHours = Int(round(driftSeconds / 3600.0))
        let driftDays = driftSeconds / 86400.0

        // 4. Consecutive Sprint Streak
        var streak = 0
        for archived in archivedMissions {
            if let completedAt = archived.completedAt, completedAt <= archived.targetDate {
                streak += 1
            } else {
                break
            }
        }
        if status == .onTrack || status == .hyperPacing {
            streak += 1
        }

        // 5. Weekly Focus Cadence
        let weeklyCadence = getWeeklyCadence()

        return VelocityReport(
            velocity: rawVelocity,
            status: status,
            driftDays: driftDays,
            driftHours: driftHours,
            projectedCompletionDate: projectedDate,
            taskProgressRatio: taskRatio,
            timeElapsedRatio: timeRatio,
            completedTasksCount: completedTasks,
            totalTasksCount: totalTasks,
            weeklyCadence: weeklyCadence,
            streakCount: streak
        )
    }

    public static func getWeeklyCadence() -> [DailyFocusCadence] {
        let calendar = Calendar.current
        let today = Date()
        let storedHistory = UserDefaults.standard.dictionary(forKey: "milestone:dailyFocusHistory") as? [String: Int] ?? [:]

        var days: [DailyFocusCadence] = []
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"

        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayKey = keyFormatter.string(from: date)
            let dayLabel = dayFormatter.string(from: date).uppercased()
            let isToday = offset == 0

            // If user has actual recorded Pomodoro minutes, use them; otherwise baseline mock for visual delight
            let storedMinutes = storedHistory[dayKey]
            let minutes: Int
            if let stored = storedMinutes {
                minutes = stored
            } else {
                // Procedural realistic focus pattern
                let baseline = [45, 60, 50, 75, 90, 40, 55]
                minutes = baseline[(offset + 3) % baseline.count]
            }

            days.append(DailyFocusCadence(
                dayKey: dayKey,
                dayLabel: dayLabel,
                minutes: minutes,
                isToday: isToday
            ))
        }

        return days
    }

    public static func recordCompletedFocusMinutes(_ minutes: Int) {
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = keyFormatter.string(from: Date())

        var storedHistory = UserDefaults.standard.dictionary(forKey: "milestone:dailyFocusHistory") as? [String: Int] ?? [:]
        let current = storedHistory[todayKey] ?? 0
        storedHistory[todayKey] = current + minutes
        UserDefaults.standard.set(storedHistory, forKey: "milestone:dailyFocusHistory")
    }
}
