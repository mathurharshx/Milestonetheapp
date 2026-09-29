import SwiftUI
import UserNotifications

public struct OnboardingView: View {
    public let onComplete: () -> Void
    @Environment(UserStore.self) private var userStore
    @Environment(MissionStore.self) private var missionStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme

    @State private var step: Int = 1
    @State private var nameInput: String = ""
    @State private var morningHour: Int = 8
    @State private var morningMinute: Int = 0
    @State private var reminderDate: Date = {
        var comps = DateComponents()
        comps.hour = 8
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @FocusState private var isNameFocused: Bool

    // Card 1: Interactive Dot Matrix Cascade Simulation
    @State private var matrixCascadeProgress: Double = 0.0
    @State private var leadDotPulse: Bool = false
    @State private var simulatedDaysElapsed: Int = 14
    private let totalSimulatedDays: Int = 30

    // Card 2: Interactive Pillar/Vault simulation
    @State private var simulatedPillar: MissionCategory = .work
    @State private var vaultSimulatedHighlight: Bool = false

    // Card 3: Interactive Focus Soundscape/Timer Simulation
    @State private var isSimulatedTimerRunning: Bool = true
    @State private var simulatedTimerSeconds: Int = 1492
    @State private var simulatedSoundscapePlaying: Bool = true

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            // ── Living Atmospheric Waves ──
            AliveDuneAtmosphereView(
                accentColor: currentAccentColor,
                secondaryColor: theme.surfaceLight,
                intensity: 0.85
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Progress Indicators (Steps 1 to 4 only, hidden on Paywall step 5)
                if step < 5 {
                    HStack(spacing: 6) {
                        ForEach(1...4, id: \.self) { idx in
                            Capsule()
                                .fill(idx <= step ? currentAccentColor : theme.border.opacity(0.4))
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

                // Step Container
                ZStack {
                    if step == 1 {
                        cardOneFiniteTime
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if step == 2 {
                        cardTwoSingleMissionAndVault
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if step == 3 {
                        cardThreeDeepWorkAudio
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if step == 4 {
                        cardFourCommitmentAndReminders
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if step == 5 {
                        PaywallSheet(
                            isEmbedded: true,
                            onContinueFree: {
                                finishOnboarding()
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: subscriptionStore.isProUser) { _, isPro in
            if isPro && step == 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    finishOnboarding()
                }
            }
        }
    }

    private var currentAccentColor: Color {
        if step == 2 && simulatedPillar == .personal {
            return AppColors.personalEmerald
        }
        return theme.accent
    }

    // ── CARD 1: THE MONOLITH / DOT MATRIX (HIGH IMPACT VISUAL HOOK) ──
    @ViewBuilder
    private var cardOneFiniteTime: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 16)

            Text("MILESTONE")
                .font(.system(size: 11, weight: .heavy))
                .tracking(4)
                .foregroundStyle(theme.accent)
                .padding(.bottom, 12)

            Text("Your time is finite.")
                .font(.system(size: 38, weight: .bold))
                .tracking(-1)
                .foregroundStyle(theme.textPrimary)
                .padding(.bottom, 10)

            Text("Every dot is one day. Watch your runway burn in real time so you never lose urgency.")
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(theme.textTertiary)
                .padding(.bottom, 24)

            // Interactive Live Runway Simulation
            VStack(spacing: 16) {
                // Large Live Runway Number
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(max(0, totalSimulatedDays - simulatedDaysElapsed))")
                        .font(.system(size: 64, weight: .ultraLight, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(theme.textPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("DAYS LEFT")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(3)
                            .foregroundStyle(theme.accent)

                        Text("30-Day Milestone Horizon")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                    }
                    Spacer()
                }

                // 30-Dot Matrix Canvas
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 6), spacing: 8) {
                    ForEach(0..<totalSimulatedDays, id: \.self) { i in
                        let isElapsed = i < simulatedDaysElapsed
                        let isLead = i == simulatedDaysElapsed
                        let isCascadeVisible = (Double(i) / Double(totalSimulatedDays)) <= matrixCascadeProgress

                        ZStack {
                            Circle()
                                .fill(isElapsed ? theme.dotElapsed : theme.dotFilled)
                                .frame(width: isLead ? 9 : 7, height: isLead ? 9 : 7)

                            if isLead {
                                Circle()
                                    .stroke(theme.accent, lineWidth: 1.5)
                                    .frame(width: 17, height: 17)
                                    .scaleEffect(leadDotPulse ? 1.25 : 0.95)
                                    .opacity(leadDotPulse ? 0.9 : 0.3)
                            }
                        }
                        .scaleEffect(isCascadeVisible ? 1.0 : 0.2)
                        .opacity(isCascadeVisible ? 1.0 : 0.0)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(theme.surface.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(theme.border.opacity(0.4), lineWidth: 1)
                        )
                )

                // Micro Legend
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle().fill(theme.dotElapsed).frame(width: 6, height: 6)
                        Text("Burned runway")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(theme.dotFilled).frame(width: 6, height: 6)
                        Text("Days remaining")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                    }
                }
            }
            .padding(.bottom, 24)

            Spacer(minLength: 16)

            Button {
                HapticsManager.shared.impact(.light)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    step = 2
                }
            } label: {
                HStack(spacing: 8) {
                    Text("CONTINUE")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(2.5)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(theme.background)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.accent)
                )
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
        .onAppear {
            matrixCascadeProgress = 0.0
            withAnimation(.easeOut(duration: 0.75)) {
                matrixCascadeProgress = 1.0
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                leadDotPulse = true
            }
        }
    }

    // ── CARD 2: ONE ACTIVE MISSION + THE VAULT (THE CORE PHILOSOPHY) ──
    @ViewBuilder
    private var cardTwoSingleMissionAndVault: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 16)

            Text("THE PRINCIPLE")
                .font(.system(size: 11, weight: .heavy))
                .tracking(4)
                .foregroundStyle(currentAccentColor)
                .padding(.bottom, 12)

            Text("One active mission.\nZero distractions.")
                .font(.system(size: 36, weight: .bold))
                .lineSpacing(-1)
                .tracking(-1)
                .foregroundStyle(theme.textPrimary)
                .padding(.bottom, 10)

            Text("Pick one mission to conquer. Park any new idea in The Vault so your momentum never splits.")
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(theme.textTertiary)
                .padding(.bottom, 20)

            // Visual Simulation: Active Mission + Cold Storage Vault
            VStack(spacing: 12) {
                // Active Mission Card (Work / Personal toggleable)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(currentAccentColor)
                                .frame(width: 7, height: 7)

                            Text(simulatedPillar == .work ? "ACTIVE WORK MISSION" : "ACTIVE PERSONAL MISSION")
                                .font(.system(size: 9.5, weight: .heavy))
                                .tracking(2)
                                .foregroundStyle(currentAccentColor)
                        }

                        Spacer()

                        Text("IN PROGRESS")
                            .font(.system(size: 8.5, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(theme.textTertiary)
                    }

                    Text(simulatedPillar == .work ? "Scale ARR to $50k" : "Run Half-Marathon")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(theme.textPrimary)

                    // Dual Pillar Switcher Simulation
                    HStack(spacing: 6) {
                        Button {
                            HapticsManager.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                simulatedPillar = .work
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "briefcase.fill").font(.system(size: 8))
                                Text("WORK").font(.system(size: 9.5, weight: .bold))
                            }
                            .foregroundStyle(simulatedPillar == .work ? theme.background : theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(simulatedPillar == .work ? theme.accent : theme.surfaceLight))
                        }
                        .buttonStyle(.plain)

                        Button {
                            HapticsManager.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                simulatedPillar = .personal
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill").font(.system(size: 8))
                                Text("PERSONAL").font(.system(size: 9.5, weight: .bold))
                            }
                            .foregroundStyle(simulatedPillar == .personal ? theme.background : theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(simulatedPillar == .personal ? AppColors.personalEmerald : theme.surfaceLight))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.surface.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(currentAccentColor.opacity(0.4), lineWidth: 1.2)
                        )
                )

                // Cold Storage Vault Drawer
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.accent.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("THE VAULT")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(2)
                                .foregroundStyle(theme.textPrimary)

                            Text("2 QUEUED")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundStyle(theme.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(theme.accent))
                        }

                        Text("Park future ideas here without breaking focus")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(theme.textTertiary)
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.surfaceLight.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.border.opacity(0.35), lineWidth: 1)
                        )
                )
            }
            .padding(.bottom, 24)

            Spacer(minLength: 16)

            Button {
                HapticsManager.shared.impact(.light)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    step = 3
                }
            } label: {
                HStack(spacing: 8) {
                    Text("CONTINUE")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(2.5)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(theme.background)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(currentAccentColor)
                )
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }

    // ── CARD 3: DEEP WORK & SOUNDSCAPES ──
    @ViewBuilder
    private var cardThreeDeepWorkAudio: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 16)

            Text("EXECUTION")
                .font(.system(size: 11, weight: .heavy))
                .tracking(4)
                .foregroundStyle(theme.accent)
                .padding(.bottom, 12)

            Text("Deep work,\nbuilt right in.")
                .font(.system(size: 38, weight: .bold))
                .lineSpacing(-1)
                .tracking(-1)
                .foregroundStyle(theme.textPrimary)
                .padding(.bottom, 10)

            Text("Laser-focused Pomodoro sessions linked to your active task, with offline 40 Hz and brown noise soundscapes.")
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(theme.textTertiary)
                .padding(.bottom, 20)

            // Visual Simulation: Integrated Pomodoro HUD + Soundscape Capsule
            VStack(spacing: 16) {
                // Central HUD Preview
                HStack(spacing: 20) {
                    // Mini Pomodoro Ring
                    ZStack {
                        Circle()
                            .stroke(theme.border.opacity(0.35), lineWidth: 5)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: 0.68)
                            .stroke(theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 80, height: 80)

                        Text("24:52")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(theme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("FOCUS SESSION • 1 OF 4")
                            .font(.system(size: 9.5, weight: .heavy))
                            .tracking(2)
                            .foregroundStyle(theme.accent)

                        Text("Finalize enterprise onboarding")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppColors.personalEmerald)
                            Text("Linked directly to active mission")
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(theme.textTertiary)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.surface.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.border.opacity(0.4), lineWidth: 1)
                        )
                )

                // Offline Soundscape Bar
                HStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACOUSTIC SOUNDSCAPES")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.5)
                            .foregroundStyle(theme.textPrimary)

                        Text("Brown Noise & 40 Hz Tone (100% on-device)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(theme.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.surfaceLight.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.bottom, 24)

            Spacer(minLength: 16)

            Button {
                HapticsManager.shared.impact(.light)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    step = 4
                }
            } label: {
                HStack(spacing: 8) {
                    Text("CONTINUE")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(2.5)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(theme.background)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.accent)
                )
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }

    // ── CARD 4: PERSONALIZATION & ACCOUNTABILITY (NAME + REMINDERS) ──
    @ViewBuilder
    private var cardFourCommitmentAndReminders: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 12)

            Text("COMMITMENT")
                .font(.system(size: 11, weight: .heavy))
                .tracking(4)
                .foregroundStyle(theme.accent)
                .padding(.bottom, 12)

            Text("Never miss\na beat.")
                .font(.system(size: 38, weight: .bold))
                .lineSpacing(-1)
                .tracking(-1)
                .foregroundStyle(theme.textPrimary)
                .padding(.bottom, 10)

            Text("Personalize your cockpit and schedule your daily morning runway reminder.")
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(theme.textTertiary)
                .padding(.bottom, 20)

            VStack(spacing: 14) {
                // Name Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR CALLSIGN OR NAME")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(theme.textSecondary)

                    TextField("Enter your name", text: $nameInput)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.border.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .focused($isNameFocused)
                        .submitLabel(.done)
                }

                // Daily Morning Reminder Time Picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DAILY RUNWAY REMINDER")
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(2)
                                .foregroundStyle(theme.textSecondary)

                            Text("Morning countdown of days & pending tasks")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(theme.textTertiary)
                        }

                        Spacer()

                        DatePicker("", selection: $reminderDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(theme.accent)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surfaceLight.opacity(0.45))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.border.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.bottom, 24)

            Spacer(minLength: 12)

            VStack(spacing: 12) {
                Button {
                    commitNameAndScheduleNotifications(requestPermission: true)
                } label: {
                    Text("ENABLE REMINDERS & CONTINUE")
                        .font(.system(size: 12.5, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(theme.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.accent)
                        )
                }

                Button {
                    HapticsManager.shared.impact(.light)
                    commitNameAndScheduleNotifications(requestPermission: false)
                } label: {
                    Text("MAYBE LATER")
                        .font(.system(size: 11.5, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }

    private func commitNameAndScheduleNotifications(requestPermission: Bool) {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        userStore.userName = trimmed.isEmpty ? "Commander" : trimmed

        let cal = Calendar.current
        userStore.morningReminderHour = cal.component(.hour, from: reminderDate)
        userStore.morningReminderMinute = cal.component(.minute, from: reminderDate)
        userStore.morningReminderEnabled = true

        isNameFocused = false

        if requestPermission {
            Task {
                HapticsManager.shared.notification(.success)
                let _ = await NotificationManager.shared.requestAuthorization()
                missionStore.refreshMorningNotification()
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        step = 5
                    }
                }
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                step = 5
            }
        }
    }

    private func finishOnboarding() {
        userStore.hasSeenOnboarding = true
        onComplete()
    }
}
