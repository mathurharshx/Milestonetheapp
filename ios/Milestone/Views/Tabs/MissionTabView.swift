import SwiftUI

public struct MissionTabView: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(PomodoroStore.self) private var pomodoroStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.theme) private var theme

    public var onNavigateToArchive: (() -> Void)?

    @State private var isCompletingAnimation: Bool = false
    @State private var showCelebrationSheet: Bool = false
    @State private var showVaultSheet: Bool = false
    @State private var completedQuote: Quote?
    @State private var activeMissionSnapshot: Mission?
    @State private var keystoneEvent: KeystoneEvent = .none

    public init(onNavigateToArchive: (() -> Void)? = nil) {
        self.onNavigateToArchive = onNavigateToArchive
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if let mission = missionStore.activeMission {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let countdown = DateCalculations.calculateFullCountdown(
                        createdAt: mission.createdAt,
                        targetDate: mission.targetDate
                    )

                    VStack(spacing: 0) {
                        // ── Top Brand & Vault Header ──
                        HStack {
                            Text("MILESTONE")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(4)
                                .foregroundStyle(theme.accent)
                                .padding(.leading, 4)

                            Spacer()

                            Button {
                                HapticsManager.shared.impact(.light)
                                showVaultSheet = true
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "archivebox")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("VAULT")
                                        .font(.system(size: 10, weight: .black))
                                        .tracking(1.5)

                                    if !missionStore.vaultMissions.isEmpty {
                                        Text("\(missionStore.vaultMissions.count)")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundStyle(theme.background)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(theme.accent))
                                    }
                                }
                                .foregroundStyle(theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(theme.surfaceLight.opacity(0.6))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                        // ── Pinned Keystone Hero Card (Living Ambient Aurora + Title + Countdown + Dot Matrix) ──
                        KeystoneCardView(event: keystoneEvent, isCompleting: isCompletingAnimation) {
                            // Mission Title
                            Text(mission.title)
                                .font(.system(size: 28, weight: .medium))
                                .tracking(-0.6)
                                .foregroundStyle(theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 12)
                                .padding(.top, 4)

                            // Countdown Timer
                            CountdownTimerView(countdown: countdown)

                            // Dot Grid Matrix with Completion Glow Wave
                            DotGridView(
                                totalDays: countdown.totalDays,
                                daysElapsed: countdown.daysElapsed,
                                totalHours: countdown.totalHours,
                                hoursElapsed: countdown.hoursElapsed,
                                isUnder24h: countdown.isUnder24h,
                                isCompleting: isCompletingAnimation
                            )
                            .padding(.bottom, 6)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                        // ── Scrollable Tasks (Only Tasks Scroll) ──
                        ScrollView(showsIndicators: false) {
                            MissionTodoListView(
                                todos: mission.todos,
                                onToggle: { id in
                                    let willBeDone = !(mission.todos.first(where: { $0.id == id })?.done ?? true)
                                    missionStore.toggleTodo(id: id)
                                    if willBeDone {
                                        keystoneEvent = .taskCompleted
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                            if keystoneEvent == .taskCompleted {
                                                keystoneEvent = .none
                                            }
                                        }
                                    }
                                },
                                onDelete: { id in
                                    missionStore.deleteTodo(id: id)
                                    keystoneEvent = .taskDeleted
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                        if keystoneEvent == .taskDeleted {
                                            keystoneEvent = .none
                                        }
                                    }
                                },
                                onMove: { indices, newOffset in
                                    missionStore.moveTodo(fromOffsets: indices, toOffset: newOffset)
                                },
                                onAddTask: { text in
                                    missionStore.addTodo(text: text)
                                    keystoneEvent = .taskAdded
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        if keystoneEvent == .taskAdded {
                                            keystoneEvent = .none
                                        }
                                    }
                                },
                                onFocusTask: { id, text in
                                    HapticsManager.shared.impact(.medium)
                                    pomodoroStore.focusOn(taskId: id, taskTitle: text)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        userStore.selectedTab = .pomodoro
                                    }
                                }
                            )
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                        }
                        .scrollIndicators(.hidden)
                        .padding(.horizontal, 24)

                        // ── Pinned Bottom Action (Mark Complete) ──
                        VStack(spacing: 0) {
                            Button {
                                triggerCompletion(for: mission)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: isCompletingAnimation ? "checkmark.circle.fill" : "checkmark.seal")
                                        .font(.system(size: 16, weight: .bold))

                                    Text(isCompletingAnimation ? "ACCOMPLISHED!" : "MARK COMPLETE")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(2.5)
                                }
                                .foregroundStyle(isCompletingAnimation ? theme.background : theme.accent)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isCompletingAnimation ? theme.accent : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(theme.accent, lineWidth: 1.5)
                                )
                                .shadow(
                                    color: isCompletingAnimation ? theme.accent.opacity(0.4) : .clear,
                                    radius: 12,
                                    x: 0,
                                    y: 4
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                            .padding(.bottom, 16)
                        }
                        .background(theme.background)
                    }
                }
            } else {
                // No active mission -> Direct creation view
                CreateMissionSheet()
            }
        }
        .fullScreenCover(isPresented: $showCelebrationSheet) {
            if let mission = activeMissionSnapshot ?? missionStore.activeMission {
                MissionCelebrationSheet(
                    mission: mission,
                    quote: completedQuote,
                    onArchive: {
                        missionStore.archiveMission()
                        isCompletingAnimation = false
                        onNavigateToArchive?()
                    },
                    onNewMission: {
                        missionStore.archiveMission()
                        isCompletingAnimation = false
                    }
                )
            }
        }
        .sheet(isPresented: $showVaultSheet) {
            VaultSheet()
        }
    }

    private func triggerCompletion(for mission: Mission) {
        // Capture snapshot before archiving
        activeMissionSnapshot = mission
        completedQuote = QuoteManager.randomQuote()

        // 1. Success Haptic Pulse & Luxury Audio Chord
        HapticsManager.shared.notification(.success)
        AudioManager.shared.play(.missionComplete)

        // 2. Cascade Dot Grid Illumination Wave
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isCompletingAnimation = true
        }

        // 3. Smooth slide-up of Apple Award Celebration Sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showCelebrationSheet = true
        }
    }
}
