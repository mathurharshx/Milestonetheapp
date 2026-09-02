import SwiftUI
import UserNotifications

public struct SettingsTabView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(ThemeStore.self) private var themeStore
    @Environment(PomodoroStore.self) private var pomodoroStore
    @Environment(MissionStore.self) private var missionStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var showProfileSheet: Bool = false
    @State private var showPaywallSheet: Bool = false
    @State private var isDarkMode: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // ── SOVEREIGN PRO BANNER ──
                    Button {
                        HapticsManager.shared.impact(.medium)
                        showPaywallSheet = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(theme.accent.opacity(0.16))
                                    .frame(width: 44, height: 44)

                                Image(systemName: subscriptionStore.isProUser ? "crown.fill" : "sparkles")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(theme.accent)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(subscriptionStore.isProUser ? "MILESTONE SOVEREIGN" : "UPGRADE TO SOVEREIGN")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundStyle(theme.textPrimary)

                                    if subscriptionStore.isProUser {
                                        Text("ACTIVE")
                                            .font(.system(size: 9, weight: .black))
                                            .tracking(1)
                                            .foregroundStyle(theme.accent)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(theme.accentDim))
                                    }
                                }

                                Text(subscriptionStore.isProUser ? "All features & focus soundscapes unlocked" : "Unlock ADHD soundscapes, the vault & dual-track")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(theme.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.textTertiary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.surfaceLight.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.accent.opacity(subscriptionStore.isProUser ? 0.35 : 0.65), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)

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

                    // Sound Effects Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sound Effects")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)

                            Text(userStore.soundEnabled ? "On" : "Off")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(theme.textTertiary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { userStore.soundEnabled },
                            set: { newValue in
                                userStore.soundEnabled = newValue
                                if newValue {
                                    AudioManager.shared.play(.pomodoroStart)
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

#if DEBUG
                    // Test / Demo Mode Toggle (Rapid 10s / 5s)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Test / Demo Mode")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)

                            Text("Rapid 10s Focus & 5s Break for testing animations")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(theme.accent)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { userStore.isTestModeEnabled },
                            set: { newValue in
                                userStore.isTestModeEnabled = newValue
                                pomodoroStore.reloadDurationsIfIdle()
                                HapticsManager.shared.impact(.light)
                            }
                        ))
                        .labelsHidden()
                        .tint(Color(uiColor: .systemGreen))
                    }
                    .padding(.vertical, 14)

                    Divider().overlay(theme.divider)

                    Button {
                        HapticsManager.shared.notification(.success)
                        let target = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                        missionStore.createMission(
                            title: "Launch Milestone v1.0",
                            targetDate: target,
                            todos: [
                                TodoTask(id: "1", text: "Submit App Store Metadata & Screenshots", done: false),
                                TodoTask(id: "2", text: "Invite TestFlight Beta Testers", done: false),
                                TodoTask(id: "3", text: "Publish Launch Announcement", done: false)
                            ]
                        )
                        userStore.selectedTab = .mission
                    } label: {
                        HStack {
                            Text("Seed Test Mission & Tasks")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(theme.accent)
                            Spacer()
                            Image(systemName: "sparkles")
                                .foregroundStyle(theme.accent)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(theme.divider)
#endif

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

                    // ── NOTIFICATIONS (APP STORE COMPLIANT) ──
                    SectionHeader(title: "NOTIFICATIONS")
                        .padding(.top, 24)

                    if notificationStatus == .denied {
                        // System Settings Navigation when permission is denied
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Notifications are Disabled")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(theme.danger)

                                    Text("Tap to enable in iOS Settings")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(theme.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(theme.accent)
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(theme.divider)
                    } else if notificationStatus == .notDetermined {
                        // Prompt to Request Permissions
                        Button {
                            Task {
                                HapticsManager.shared.impact(.light)
                                let _ = await NotificationManager.shared.requestAuthorization()
                                await checkNotificationStatus()
                                missionStore.refreshMorningNotification()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Enable Notifications")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("Receive focus timer alerts and morning updates")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(theme.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "bell.badge")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(theme.accent)
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(theme.divider)
                    } else {
                        // Focus Timer Completion Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Timer Completion Alerts")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(theme.textPrimary)

                                Text("Alert when focus or break sessions end")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(theme.textTertiary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { userStore.timerNotificationsEnabled },
                                set: { newValue in
                                    userStore.timerNotificationsEnabled = newValue
                                    HapticsManager.shared.impact(.light)
                                    if !newValue {
                                        NotificationManager.shared.cancelPomodoroNotifications()
                                    }
                                }
                            ))
                            .labelsHidden()
                            .tint(Color(uiColor: .systemGreen))
                        }
                        .padding(.vertical, 14)

                        Divider().overlay(theme.divider)

                        // Daily Morning Reminder Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Mission Reminder")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(theme.textPrimary)

                                Text("Morning countdown and pending tasks")
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
                                        missionStore.refreshMorningNotification()
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
                    }

                    // ── ABOUT SECTION ──
                    SectionHeader(title: "ABOUT")
                        .padding(.top, 24)

                    SettingsRow(
                        label: "Milestone",
                        sublabel: "Version 1.0.0 (1)",
                        showChevron: false
                    )

                    Divider().overlay(theme.divider)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(theme.background.ignoresSafeArea())
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallSheet()
        }
        .onAppear {
            isDarkMode = themeStore.isDarkMode(systemScheme: colorScheme)
            var comps = DateComponents()
            comps.hour = userStore.morningReminderHour
            comps.minute = userStore.morningReminderMinute
            reminderDate = Calendar.current.date(from: comps) ?? Date()

            Task {
                await checkNotificationStatus()
            }
        }
        .onChange(of: colorScheme) { _, newScheme in
            if themeStore.mode == .system {
                isDarkMode = newScheme == .dark
            }
        }
    }

    private func checkNotificationStatus() async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        await MainActor.run {
            self.notificationStatus = status
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
