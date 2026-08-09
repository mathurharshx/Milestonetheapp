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
        }
    }

    public init() {
        self.userName = UserDefaults.standard.string(forKey: "milestone:userName") ?? ""
        let seenString = UserDefaults.standard.string(forKey: "milestone:hasSeenOnboarding")
        self.hasSeenOnboarding = seenString == "true"
        self.hapticsEnabled = HapticsManager.shared.isEnabled
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
