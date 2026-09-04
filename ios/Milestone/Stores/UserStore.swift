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
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "milestone:hasSeenOnboarding")
        }
    }

    public var hapticsEnabled: Bool {
        didSet {
            HapticsManager.shared.isEnabled = hapticsEnabled
            UserDefaults.standard.set(hapticsEnabled, forKey: "milestone:hapticsEnabled")
        }
    }

    public var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "milestone:soundEnabled")
        }
    }

    // ── Active Navigation Tab & Paywall ──
    public var selectedTab: TabItem = .mission
    public var showPaywallSheet: Bool = false

    public func handleDeepLink(url: URL) {
        let str = url.absoluteString.lowercased()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if str.contains("premium") || str.contains("paywall") {
                showPaywallSheet = true
            } else if str.contains("pomodoro") {
                selectedTab = .pomodoro
            } else if str.contains("mission") {
                selectedTab = .mission
            } else if str.contains("archive") {
                selectedTab = .archive
            } else if str.contains("settings") {
                selectedTab = .settings
            }
        }
    }

    // ── Test Mode for Rapid Pomodoro Testing ──
    public var isTestModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isTestModeEnabled, forKey: "milestone:isTestModeEnabled")
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

    // ── Notification Preferences ──
    public var timerNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(timerNotificationsEnabled, forKey: "milestone:timerNotificationsEnabled")
        }
    }

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
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "milestone:hasSeenOnboarding")
        
        let savedHaptics = UserDefaults.standard.object(forKey: "milestone:hapticsEnabled") as? Bool ?? true
        self.hapticsEnabled = savedHaptics
        HapticsManager.shared.isEnabled = savedHaptics

        let savedFocus = UserDefaults.standard.integer(forKey: "milestone:focusDuration")
        self.focusDurationMinutes = savedFocus > 0 ? savedFocus : 25

        let savedShortBreak = UserDefaults.standard.integer(forKey: "milestone:shortBreakDuration")
        self.shortBreakDurationMinutes = savedShortBreak > 0 ? savedShortBreak : 5

        let savedLongBreak = UserDefaults.standard.integer(forKey: "milestone:longBreakDuration")
        self.longBreakDurationMinutes = savedLongBreak > 0 ? savedLongBreak : 20

        self.timerNotificationsEnabled = UserDefaults.standard.object(forKey: "milestone:timerNotificationsEnabled") as? Bool ?? true
        self.morningReminderEnabled = UserDefaults.standard.object(forKey: "milestone:morningReminderEnabled") as? Bool ?? true
        let savedHour = UserDefaults.standard.object(forKey: "milestone:morningReminderHour") as? Int ?? 9
        self.morningReminderHour = savedHour
        let savedMin = UserDefaults.standard.object(forKey: "milestone:morningReminderMinute") as? Int ?? 0
        self.morningReminderMinute = savedMin
        self.isTestModeEnabled = UserDefaults.standard.bool(forKey: "milestone:isTestModeEnabled")
        self.soundEnabled = UserDefaults.standard.object(forKey: "milestone:soundEnabled") as? Bool ?? true
    }
}

@Observable
public final class ThemeStore {
    public var mode: AppThemeMode = .dark

    public init() {
        self.mode = .dark
        syncToWidget()
    }

    public func toggleTheme(systemScheme: ColorScheme? = nil) {
        mode = .dark
    }

    public func setTheme(isDark: Bool) {
        mode = .dark
    }

    public func isDarkMode(systemScheme: ColorScheme? = nil) -> Bool {
        return true
    }

    public func tokens(systemScheme: ColorScheme? = nil) -> ThemeTokens {
        return ThemeTokens(isDark: true)
    }

    public func syncToWidget(systemScheme: ColorScheme? = nil) {
        if var data = SharedWidgetStore.load() {
            data.isDarkMode = true
            SharedWidgetStore.save(data)
        } else {
            var data = MilestoneWidgetData()
            data.isDarkMode = true
            SharedWidgetStore.save(data)
        }
    }
}
