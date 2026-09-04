import SwiftUI

public enum AppThemeMode: String, CaseIterable, Codable {
    case dark = "dark"
    case system = "system"
    case light = "light"

    public var colorScheme: ColorScheme? {
        return .dark
    }
}

public struct AppColors {
    // Exact hex colors matching brutalist obsidian theme
    public static let lightBackground = Color(red: 0xF2/255.0, green: 0xF2/255.0, blue: 0xF7/255.0) // #F2F2F7
    public static let lightSurface = Color(red: 0xE5/255.0, green: 0xE5/255.0, blue: 0xEA/255.0)    // #E5E5EA
    public static let lightSurfaceLight = Color(red: 0xD1/255.0, green: 0xD1/255.0, blue: 0xD6/255.0) // #D1D1D6
    public static let lightCharcoal = Color(red: 0x22/255.0, green: 0x22/255.0, blue: 0x22/255.0)   // #222222

    public static let darkBackground = Color(red: 0x22/255.0, green: 0x22/255.0, blue: 0x22/255.0)  // #222222
    public static let darkSurface = Color(red: 0x2A/255.0, green: 0x2A/255.0, blue: 0x2A/255.0)     // #2A2A2A
    public static let darkSurfaceLight = Color(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0)// #333333

    public static let danger = Color(red: 0xC0/255.0, green: 0x39/255.0, blue: 0x2B/255.0)          // #C0392B
}

public struct ThemeTokens {
    public let isDark: Bool = true

    public init(isDark: Bool = true) {}

    public var background: Color {
        AppColors.darkBackground
    }

    public var surface: Color {
        AppColors.darkSurface
    }

    public var surfaceLight: Color {
        AppColors.darkSurfaceLight
    }

    public var textPrimary: Color {
        AppColors.lightBackground
    }

    public var textSecondary: Color {
        textPrimary.opacity(0.60)
    }

    public var textTertiary: Color {
        textPrimary.opacity(0.35)
    }

    public var textMuted: Color {
        textPrimary.opacity(0.18)
    }

    public var accent: Color {
        textPrimary
    }

    public var accentDim: Color {
        textPrimary.opacity(0.10)
    }

    public var accentMuted: Color {
        textPrimary.opacity(0.05)
    }

    public var dotFilled: Color {
        textPrimary.opacity(0.80)
    }

    public var dotElapsed: Color {
        textPrimary.opacity(0.15)
    }

    public var dotEmpty: Color {
        textPrimary.opacity(0.08)
    }

    public var border: Color {
        textPrimary.opacity(0.08)
    }

    public var divider: Color {
        textPrimary.opacity(0.05)
    }

    public var danger: Color {
        AppColors.danger
    }
}

// SwiftUI Environment Key for ThemeTokens
private struct ThemeTokensKey: EnvironmentKey {
    static let defaultValue = ThemeTokens(isDark: false)
}

extension EnvironmentValues {
    public var theme: ThemeTokens {
        get { self[ThemeTokensKey.self] }
        set { self[ThemeTokensKey.self] = newValue }
    }
}
