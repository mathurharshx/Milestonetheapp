import SwiftUI

public struct PomodoroTabView: View {
    @Environment(PomodoroStore.self) private var pomodoroStore
    @Environment(\.theme) private var theme

    @State private var flashOpacity: Double = 0.0
    @State private var flashColor: Color = Color(red: 0.32, green: 0.72, blue: 0.53)

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
                Spacer()

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
                .padding(.bottom, 28)

                // Circular Progress Ring
                PomodoroRingView(
                    progress: pomodoroStore.progress,
                    timeRemaining: pomodoroStore.timeRemaining,
                    isRunning: pomodoroStore.isRunning,
                    isStarted: pomodoroStore.isStarted,
                    phase: pomodoroStore.phase,
                    color: phaseColor,
                    message: pomodoroStore.activeBreakPrompt
                )
                .padding(.bottom, 36)

                // Controls
                HStack(spacing: 16) {
                    if !pomodoroStore.isRunning {
                        Button {
                            HapticsManager.shared.impact(.medium)
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
    }

    private func triggerPhaseFlash() {
        if pomodoroStore.phase == .focus {
            flashColor = theme.accent.opacity(0.8)
        } else {
            flashColor = Color(red: 0.32, green: 0.72, blue: 0.53) // Serene Emerald
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
