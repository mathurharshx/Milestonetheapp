import SwiftUI

public struct SettingsTabView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var showProfileSheet: Bool = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("MILESTONE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(theme.accent)

                Text("Settings")
                    .font(.system(size: 36, weight: .light))
                    .tracking(-1)
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)

            // Settings Rows
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Row
                    Button {
                        showProfileSheet = true
                    } label: {
                        SettingsRow(
                            label: "Profile",
                            sublabel: userStore.userName.isEmpty ? "Set your name" : userStore.userName,
                            showChevron: true
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(theme.divider)

                    // Appearance Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appearance")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)

                            Text(theme.isDark ? "Dark" : "Light")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(theme.textTertiary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { theme.isDark },
                            set: { _ in
                                HapticsManager.shared.impact(.light)
                                themeStore.toggleTheme(systemScheme: colorScheme)
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 16)

                    Divider().overlay(theme.divider)

                    // Haptics Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Haptics")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)

                            Text(userStore.hapticsEnabled ? "On" : "Off")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(theme.textTertiary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { userStore.hapticsEnabled },
                            set: { newValue in
                                userStore.hapticsEnabled = newValue
                                if newValue {
                                    HapticsManager.shared.impact(.medium)
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 16)

                    Divider().overlay(theme.divider)

                    // About
                    SettingsRow(
                        label: "About",
                        sublabel: "v1.0.0",
                        showChevron: false
                    )

                    Divider().overlay(theme.divider)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(theme.background.ignoresSafeArea())
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
        }
    }
}

private struct SettingsRow: View {
    let label: String
    let sublabel: String?
    let showChevron: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.textPrimary)

                if let sublabel = sublabel {
                    Text(sublabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(theme.textTertiary)
                }
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(theme.textMuted)
            }
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}
