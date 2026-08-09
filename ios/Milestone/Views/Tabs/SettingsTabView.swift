import SwiftUI
import UserNotifications

public struct SettingsTabView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(ThemeStore.self) private var themeStore
    @Environment(PomodoroStore.self) private var pomodoroStore
    @Environment(MissionStore.self) private var missionStore
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var showProfileSheet: Bool = false
    @State private var isDarkMode: Bool = false
    @State private var reminderDate: Date = Date()

    private let focusOptions = [15, 20, 25, 30, 45, 50, 60]
    private let shortBreakOptions = [3, 5, 10]
    private let longBreakOptions = [15, 20, 30]

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
            .padding(.bottom, 20)

            // Settings Rows
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // ── GENERAL SECTION ──
                    SectionHeader(title: "GENERAL")

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

                    // Appearance Toggle (Smooth Native Switch)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appearance")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)

                            Text(isDarkMode ? "Dark" : "Light")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(theme.textTertiary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { isDarkMode },
                            set: { newValue in
                                isDarkMode = newValue
                                HapticsManager.shared.impact(.light)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                                    withAnimation(.easeInOut(duration: 0.28)) {
                                        themeStore.setTheme(isDark: newValue)
                                    }
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(Color(uiColor: .systemGreen))
                    }
                    .padding(.vertical, 14)

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
                        .tint(Color(uiColor: .systemGreen))
                    }
                    .padding(.vertical, 14)

                    Divider().overlay(theme.divider)

                    // ── FOCUS TIMERS (ADHD RHYTHM) ──
                    SectionHeader(title: "FOCUS TIMERS")
                        .padding(.top, 24)

                    // Focus Duration Picker
                    HStack {
                        Text("Focus Duration")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(theme.textPrimary)

                        Spacer()

                        Picker("Focus Duration", selection: Binding(
                            get: { userStore.focusDurationMinutes },
                            set: { newValue in
                                userStore.focusDurationMinutes = newValue
                                pomodoroStore.reloadDurationsIfIdle()
                                HapticsManager.shared.selection()
                            }
                        )) {
                            ForEach(focusOptions, id: \.self) { mins in
                                Text("\(mins) min").tag(mins)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(theme.accent)
                    }
                    .padding(.vertical, 10)

                    Divider().overlay(theme.divider)

                    // Short Break Duration Picker
                    HStack {
                        Text("Short Break")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(theme.textPrimary)

                        Spacer()

                        Picker("Short Break", selection: Binding(
                            get: { userStore.shortBreakDurationMinutes },
                            set: { newValue in
                                userStore.shortBreakDurationMinutes = newValue
                                pomodoroStore.reloadDurationsIfIdle()
                                HapticsManager.shared.selection()
                            }
                        )) {
                            ForEach(shortBreakOptions, id: \.self) { mins in
                                Text("\(mins) min").tag(mins)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(theme.accent)
                    }
                    .padding(.vertical, 10)

                    Divider().overlay(theme.divider)

                    // Long Break Duration Picker
                    HStack {
                        Text("Long Break")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(theme.textPrimary)

                        Spacer()

                        Picker("Long Break", selection: Binding(
                            get: { userStore.longBreakDurationMinutes },
                            set: { newValue in
                                userStore.longBreakDurationMinutes = newValue
                                pomodoroStore.reloadDurationsIfIdle()
                                HapticsManager.shared.selection()
                            }
                        )) {
                            ForEach(longBreakOptions, id: \.self) { mins in
                                Text("\(mins) min").tag(mins)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(theme.accent)
                    }
                    .padding(.vertical, 10)

                    Divider().overlay(theme.divider)

                    // ── NOTIFICATIONS ──
                    SectionHeader(title: "NOTIFICATIONS")
                        .padding(.top, 24)

                    // Daily Morning Reminder Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Mission Reminder")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)

                            Text("Morning countdown & pending tasks")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(theme.textTertiary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { userStore.morningReminderEnabled },
                            set: { newValue in
                                userStore.morningReminderEnabled = newValue
                                HapticsManager.shared.impact(.light)
                                if newValue {
                                    Task {
                                        let _ = await NotificationManager.shared.requestAuthorization()
                                        missionStore.refreshMorningNotification()
                                    }
                                } else {
                                    NotificationManager.shared.cancelDailyMorningReminder()
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(Color(uiColor: .systemGreen))
                    }
                    .padding(.vertical, 14)

                    if userStore.morningReminderEnabled {
                        Divider().overlay(theme.divider)

                        // Reminder Time Picker
                        HStack {
                            Text("Reminder Time")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)

                            Spacer()

                            DatePicker("", selection: $reminderDate, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(theme.accent)
                                .onChange(of: reminderDate) { _, newDate in
                                    let cal = Calendar.current
                                    userStore.morningReminderHour = cal.component(.hour, from: newDate)
                                    userStore.morningReminderMinute = cal.component(.minute, from: newDate)
                                    missionStore.refreshMorningNotification()
                                }
                        }
                        .padding(.vertical, 10)
                    }

                    Divider().overlay(theme.divider)

                    // ── ABOUT SECTION ──
                    SectionHeader(title: "ABOUT")
                        .padding(.top, 24)

                    SettingsRow(
                        label: "Milestone",
                        sublabel: "v1.0.0 (Submission Build)",
                        showChevron: false
                    )

                    Divider().overlay(theme.divider)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(theme.background.ignoresSafeArea())
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
        }
        .onAppear {
            isDarkMode = themeStore.isDarkMode(systemScheme: colorScheme)
            var comps = DateComponents()
            comps.hour = userStore.morningReminderHour
            comps.minute = userStore.morningReminderMinute
            reminderDate = Calendar.current.date(from: comps) ?? Date()
        }
        .onChange(of: colorScheme) { _, newScheme in
            if themeStore.mode == .system {
                isDarkMode = newScheme == .dark
            }
        }
    }
}

// ── Section Header ──
private struct SectionHeader: View {
    let title: String
    @Environment(\.theme) private var theme

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .heavy))
            .tracking(2.5)
            .foregroundStyle(theme.textTertiary)
            .padding(.bottom, 8)
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
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
