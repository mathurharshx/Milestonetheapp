import SwiftUI
import Observation

@Observable
public final class UserStore {
    public var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "milestone:userName")
        }
    }

    public var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding ? "true" : "false", forKey: "milestone:hasSeenOnboarding")
        }
    }

    public var hapticsEnabled: Bool {
        didSet {
            HapticsManager.shared.isEnabled = hapticsEnabled
            UserDefaults.standard.set(hapticsEnabled, forKey: "milestone:hapticsEnabled")
        }
    }

    // ── Customizable Pomodoro Durations (Minutes) ──
    public var focusDurationMinutes: Int {
        didSet {
            UserDefaults.standard.set(focusDurationMinutes, forKey: "milestone:focusDuration")
        }
    }

    public var shortBreakDurationMinutes: Int {
        didSet {
            UserDefaults.standard.set(shortBreakDurationMinutes, forKey: "milestone:shortBreakDuration")
        }
    }

    public var longBreakDurationMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakDurationMinutes, forKey: "milestone:longBreakDuration")
        }
    }

    // ── Daily Morning Accountability Notification ──
    public var morningReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(morningReminderEnabled, forKey: "milestone:morningReminderEnabled")
        }
    }

    public var morningReminderHour: Int {
        didSet {
            UserDefaults.standard.set(morningReminderHour, forKey: "milestone:morningReminderHour")
        }
    }

    public var morningReminderMinute: Int {
        didSet {
            UserDefaults.standard.set(morningReminderMinute, forKey: "milestone:morningReminderMinute")
        }
    }

    public init() {
        self.userName = UserDefaults.standard.string(forKey: "milestone:userName") ?? ""
        let seenString = UserDefaults.standard.string(forKey: "milestone:hasSeenOnboarding")
        self.hasSeenOnboarding = seenString == "true"
        
        let savedHaptics = UserDefaults.standard.object(forKey: "milestone:hapticsEnabled") as? Bool ?? true
        self.hapticsEnabled = savedHaptics
        HapticsManager.shared.isEnabled = savedHaptics

        let savedFocus = UserDefaults.standard.integer(forKey: "milestone:focusDuration")
        self.focusDurationMinutes = savedFocus > 0 ? savedFocus : 25

        let savedShortBreak = UserDefaults.standard.integer(forKey: "milestone:shortBreakDuration")
        self.shortBreakDurationMinutes = savedShortBreak > 0 ? savedShortBreak : 5

        let savedLongBreak = UserDefaults.standard.integer(forKey: "milestone:longBreakDuration")
        self.longBreakDurationMinutes = savedLongBreak > 0 ? savedLongBreak : 20

        self.morningReminderEnabled = UserDefaults.standard.object(forKey: "milestone:morningReminderEnabled") as? Bool ?? true
        let savedHour = UserDefaults.standard.object(forKey: "milestone:morningReminderHour") as? Int ?? 9
        self.morningReminderHour = savedHour
        let savedMin = UserDefaults.standard.object(forKey: "milestone:morningReminderMinute") as? Int ?? 0
        self.morningReminderMinute = savedMin
    }
}

@Observable
public final class ThemeStore {
    public var mode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "milestone:themeMode")
        }
    }

    public init() {
        let raw = UserDefaults.standard.string(forKey: "milestone:themeMode") ?? "system"
        self.mode = AppThemeMode(rawValue: raw) ?? .system
    }

    public func toggleTheme(systemScheme: ColorScheme?) {
        let currentIsDark: Bool
        if mode == .system {
            currentIsDark = systemScheme == .dark
        } else {
            currentIsDark = mode == .dark
        }
        mode = currentIsDark ? .light : .dark
    }

    public func setTheme(isDark: Bool) {
        mode = isDark ? .dark : .light
    }

    public func isDarkMode(systemScheme: ColorScheme?) -> Bool {
        switch mode {
        case .system:
            return systemScheme == .dark
        case .dark:
            return true
        case .light:
            return false
        }
    }

    public func tokens(systemScheme: ColorScheme?) -> ThemeTokens {
        let isDark = isDarkMode(systemScheme: systemScheme)
        return ThemeTokens(isDark: isDark)
    }
}
