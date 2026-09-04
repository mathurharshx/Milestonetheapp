import SwiftUI

public struct PomodoroTabView: View {
    @Environment(PomodoroStore.self) private var pomodoroStore
    @Environment(MissionStore.self) private var missionStore
    @Environment(UserStore.self) private var userStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(SoundscapeManager.self) private var soundscapeManager
    @Environment(\.theme) private var theme

    @State private var flashOpacity: Double = 0.0
    @State private var flashColor: Color = Color(red: 0.32, green: 0.72, blue: 0.53)
    @State private var showPaywall: Bool = false

    public init() {}

    private var phaseColor: Color {
        switch pomodoroStore.phase {
        case .focus:
            return theme.accent
        case .shortBreak, .longBreak:
            return Color(red: 0.32, green: 0.72, blue: 0.53) // Serene Sage Emerald
        }
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            // Subtle Ambient Screen Flash Pulse on Phase Transition
            flashColor
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
#if DEBUG
                if userStore.isTestModeEnabled {
                    Text("TEST MODE (10s Focus / 5s Break)")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(theme.accent.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.top, 16)
                }
#endif

                Spacer()

                // Active Focused Task Pill
                if let taskTitle = pomodoroStore.activeTaskTitle {
                    HStack(spacing: 8) {
                        Image(systemName: "scope")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.accent)

                        Text(taskTitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)

                        Button {
                            HapticsManager.shared.impact(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                pomodoroStore.clearActiveTask()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(theme.surfaceLight)
                    )
                    .overlay(
                        Capsule()
                            .stroke(theme.accent.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .scale))
                }

                // Phase Badge
                Text(pomodoroStore.phase.title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3.5)
                    .foregroundStyle(phaseColor)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(phaseColor.opacity(0.14))
                    )
                    .padding(.bottom, 20)

                // Session Dots (1 to 4)
                HStack(spacing: 6) {
                    ForEach(1...pomodoroStore.totalSessions, id: \.self) { i in
                        let isCurrent = (i == pomodoroStore.currentSession && pomodoroStore.phase == .focus)
                        let isActive = i < pomodoroStore.currentSession

                        Circle()
                            .fill(isCurrent ? phaseColor : (isActive ? phaseColor.opacity(0.3) : theme.dotEmpty))
                            .frame(width: 7, height: 7)
                            .scaleEffect(isCurrent ? 1.3 : 1.0)
                    }

                    Text("\(pomodoroStore.currentSession) / \(pomodoroStore.totalSessions)")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(theme.textTertiary)
                        .padding(.leading, 6)
                }
                .padding(.bottom, 12)

                // ── ADHD Focus Soundscape Pill ──
                HStack(spacing: 8) {
                    Button {
                        HapticsManager.shared.impact(.light)
                        if subscriptionStore.isProUser {
                            soundscapeManager.togglePlayPause()
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: soundscapeManager.isPlaying ? "waveform" : "speaker.wave.2")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(soundscapeManager.isPlaying ? theme.accent : theme.textTertiary)

                            Text(soundscapeManager.isPlaying ? soundscapeManager.currentSoundscape.rawValue : "Focus Soundscape")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(soundscapeManager.isPlaying ? theme.textPrimary : theme.textSecondary)

                            if !subscriptionStore.isProUser {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(theme.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(theme.surfaceLight.opacity(0.6))
                        )
                        .overlay(
                            Capsule()
                                .stroke(soundscapeManager.isPlaying ? theme.accent.opacity(0.6) : theme.border.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    if subscriptionStore.isProUser {
                        Menu {
                            ForEach(SoundscapeType.allCases) { type in
                                Button {
                                    soundscapeManager.setSoundscape(type)
                                } label: {
                                    Label(type.rawValue, systemImage: type.icon)
                                }
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme.textTertiary)
                                .padding(7)
                                .background(
                                    Circle()
                                        .fill(theme.surfaceLight.opacity(0.5))
                                )
                        }
                    }
                }
                .padding(.bottom, 16)

                // Circular Progress Ring
                PomodoroRingView(
                    progress: pomodoroStore.progress,
                    timeRemaining: pomodoroStore.timeRemaining,
                    isRunning: pomodoroStore.isRunning,
                    isStarted: pomodoroStore.isStarted,
                    phase: pomodoroStore.phase,
                    color: phaseColor,
                    message: pomodoroStore.activeBreakPrompt,
                    isSoundscapePlaying: soundscapeManager.isPlaying
                )
                .padding(.bottom, 36)

                // Controls
                HStack(spacing: 16) {
                    if !pomodoroStore.isRunning {
                        Button {
                            HapticsManager.shared.impact(.medium)
                            AudioManager.shared.play(.pomodoroStart)
                            pomodoroStore.start()
                        } label: {
                            Text(pomodoroStore.isStarted ? "RESUME" : "START")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(3.5)
                                .foregroundStyle(theme.background)
                                .frame(minWidth: 140, minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(phaseColor)
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Button {
                            HapticsManager.shared.impact(.light)
                            pomodoroStore.pause()
                        } label: {
                            Text("PAUSE")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(3.5)
                                .foregroundStyle(phaseColor)
                                .frame(minWidth: 140, minHeight: 52)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(phaseColor.opacity(0.3), lineWidth: 1)
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if pomodoroStore.isStarted {
                        Button {
                            HapticsManager.shared.impact(.light)
                            pomodoroStore.reset()
                        } label: {
                            Text("RESET")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(2)
                                .foregroundStyle(theme.textTertiary)
                                .frame(minWidth: 80, minHeight: 52)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Next Up Phase Banner
                if pomodoroStore.isStarted {
                    HStack(spacing: 10) {
                        Text("NEXT")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(2.5)
                            .foregroundStyle(theme.textMuted)

                        Rectangle()
                            .fill(theme.border)
                            .frame(width: 16, height: 1)

                        Text(pomodoroStore.nextPhaseLabel)
                            .font(.system(size: 12, weight: .regular))
                            .tracking(0.5)
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(.top, 32)
                }

                // Complete Linked Task Action
                if let taskId = pomodoroStore.activeTaskId {
                    Button {
                        HapticsManager.shared.notification(.success)
                        missionStore.toggleTodo(id: taskId)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            pomodoroStore.clearActiveTask()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("COMPLETE TASK")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.8)
                        }
                        .foregroundStyle(Color(uiColor: .systemGreen))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule().fill(Color(uiColor: .systemGreen).opacity(0.12))
                        )
                        .overlay(
                            Capsule().stroke(Color(uiColor: .systemGreen).opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            pomodoroStore.syncFromWidget()
        }
        .onChange(of: pomodoroStore.phaseTransitionCount) { _, _ in
            triggerPhaseFlash()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
        }
    }

    private func triggerPhaseFlash() {
        if pomodoroStore.phase == .focus {
            flashColor = theme.accent.opacity(0.8)
            AudioManager.shared.play(.breakComplete)
        } else {
            flashColor = Color(red: 0.32, green: 0.72, blue: 0.53) // Serene Emerald
            AudioManager.shared.play(.focusComplete)
        }

        withAnimation(.easeIn(duration: 0.28)) {
            flashOpacity = 0.25
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeOut(duration: 0.28)) {
                flashOpacity = 0.05
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                withAnimation(.easeIn(duration: 0.22)) {
                    flashOpacity = 0.20
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    withAnimation(.easeOut(duration: 0.38)) {
                        flashOpacity = 0.0
                    }
                }
            }
        }
    }
}
