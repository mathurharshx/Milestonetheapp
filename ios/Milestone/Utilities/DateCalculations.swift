import Foundation

public struct CountdownData: Equatable {
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Int
    public let totalDays: Int
    public let daysElapsed: Int
    public let daysRemaining: Int
    public let totalHours: Int
    public let hoursElapsed: Int
    public let isUnder24h: Bool
    public let progressPercent: Int
    public let isExpired: Bool

    public static let empty = CountdownData(
        days: 0, hours: 0, minutes: 0, seconds: 0,
        totalDays: 1, daysElapsed: 0, daysRemaining: 0,
        totalHours: 0, hoursElapsed: 0, isUnder24h: false,
        progressPercent: 0, isExpired: false
    )
}

public enum DateCalculations {
    private static var calendar: Calendar { Calendar.current }

    public static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    public static func differenceInDays(from startDate: Date, to endDate: Date) -> Int {
        let start = startOfDay(startDate)
        let end = startOfDay(endDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    public static func getDaysRemaining(targetDate: Date) -> Int {
        max(0, differenceInDays(from: Date(), to: targetDate))
    }

    public static func getDaysElapsed(createdAt: Date) -> Int {
        max(0, differenceInDays(from: createdAt, to: Date()))
    }

    public static func getTotalDays(createdAt: Date, targetDate: Date) -> Int {
        max(1, differenceInDays(from: createdAt, to: targetDate))
    }

    public static func calculateFullCountdown(createdAt: Date, targetDate: Date) -> CountdownData {
        let now = Date()
        let diff = targetDate.timeIntervalSince(now)

        let totalDays = getTotalDays(createdAt: createdAt, targetDate: targetDate)
        let daysElapsed = getDaysElapsed(createdAt: createdAt)
        let daysRemaining = getDaysRemaining(targetDate: targetDate)
        let progressPercent = totalDays > 0 ? min(100, Int(round((Double(daysElapsed) / Double(totalDays)) * 100))) : 0

        let totalMs = targetDate.timeIntervalSince(createdAt)
        let elapsedMs = now.timeIntervalSince(createdAt)
        let totalHours = max(1, Int(ceil(totalMs / 3600)))
        let hoursElapsed = max(0, min(totalHours, Int(floor(elapsedMs / 3600))))
        let isUnder24h = totalMs < (24 * 3600)

        if diff <= 0 {
            return CountdownData(
                days: 0, hours: 0, minutes: 0, seconds: 0,
                totalDays: totalDays, daysElapsed: daysElapsed, daysRemaining: 0,
                totalHours: totalHours, hoursElapsed: totalHours, isUnder24h: isUnder24h,
                progressPercent: 100, isExpired: true
            )
        }

        let totalSeconds = Int(diff)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return CountdownData(
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            totalDays: totalDays,
            daysElapsed: daysElapsed,
            daysRemaining: daysRemaining,
            totalHours: totalHours,
            hoursElapsed: hoursElapsed,
            isUnder24h: isUnder24h,
            progressPercent: progressPercent,
            isExpired: false
        )
    }

    public static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    public static func formatDuration(startDate: Date, endDate: Date) -> String {
        let days = max(0, differenceInDays(from: startDate, to: endDate))
        if days < 7 {
            return "\(days) day\(days != 1 ? "s" : "")"
        }
        if days < 30 {
            let weeks = days / 7
            return "\(weeks) week\(weeks != 1 ? "s" : "")"
        }
        let months = days / 30
        return "\(months) month\(months != 1 ? "s" : "")"
    }
}
