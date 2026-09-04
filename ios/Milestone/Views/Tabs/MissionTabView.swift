import SwiftUI

public struct MissionTabView: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(PomodoroStore.self) private var pomodoroStore
    @Environment(UserStore.self) private var userStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme

    public var onNavigateToArchive: (() -> Void)?

    @State private var isCompletingAnimation: Bool = false
    @State private var isAscendingToVault: Bool = false
    @State private var vaultPulse: CGFloat = 1.0
    @State private var showCelebrationSheet: Bool = false
    @State private var showVaultSheet: Bool = false
    @State private var showPaywallSheet: Bool = false
    @State private var paywallFeature: PaywallSheet.PremiumFeature? = nil
    @State private var showCreateMissionSheet: Bool = false
    @State private var completedQuote: Quote?
    @State private var activeMissionSnapshot: Mission?
    @State private var keystoneEvent: KeystoneEvent = .none

    @Namespace private var pillarNamespace

    public init(onNavigateToArchive: (() -> Void)? = nil) {
        self.onNavigateToArchive = onNavigateToArchive
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if let mission = missionStore.currentPillarMission {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let countdown = DateCalculations.calculateFullCountdown(
                        createdAt: mission.createdAt,
                        targetDate: mission.targetDate
                    )

                    VStack(spacing: 0) {
                        // ── Top Brand, Dual Pillars & Vault Header ──
                        topHeaderBar

                        // ── Pinned Keystone Hero Card (Living Ambient Aurora + Title + Countdown + Dot Matrix + Velocity) ──
                        KeystoneCardView(
                            event: keystoneEvent,
                            isCompleting: isCompletingAnimation,
                            isAscending: isAscendingToVault
                        ) {
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

                            // Dot Grid Matrix with Completion Glow Wave (<48h / <24h sprint tracks)
                            DotGridView(
                                totalDays: countdown.totalDays,
                                daysElapsed: countdown.daysElapsed,
                                totalHours: countdown.totalHours,
                                hoursElapsed: countdown.hoursElapsed,
                                hoursRemaining: countdown.hoursRemaining,
                                isUnder24h: countdown.isUnder24h,
                                isUnder48h: countdown.isUnder48h,
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
                                .foregroundStyle(isCompletingAnimation ? theme.background : (mission.category == .personal ? Color(red: 0.32, green: 0.72, blue: 0.53) : theme.accent))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isCompletingAnimation ? (mission.category == .personal ? Color(red: 0.32, green: 0.72, blue: 0.53) : theme.accent) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(mission.category == .personal ? Color(red: 0.32, green: 0.72, blue: 0.53) : theme.accent, lineWidth: 1.5)
                                )
                                .shadow(
                                    color: isCompletingAnimation ? (mission.category == .personal ? Color(red: 0.32, green: 0.72, blue: 0.53).opacity(0.4) : theme.accent.opacity(0.4)) : .clear,
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
                VStack(spacing: 0) {
                    topHeaderBar

                    if missionStore.activePillar == .personal {
                        personalPillarEmptyState
                    } else {
                        // Work Mission direct creation view
                        CreateMissionSheet(category: .work)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallSheet(initialFeature: paywallFeature)
        }
        .sheet(isPresented: $showCreateMissionSheet) {
            CreateMissionSheet(category: .personal)
        }
        .sheet(isPresented: $showVaultSheet) {
            VaultSheet()
        }
        .fullScreenCover(isPresented: $showCelebrationSheet) {
            if let mission = activeMissionSnapshot ?? missionStore.currentPillarMission {
                MissionCelebrationSheet(
                    mission: mission,
                    quote: completedQuote,
                    onArchive: {
                        missionStore.archiveMission()
                        isCompletingAnimation = false
                        isAscendingToVault = false
                        onNavigateToArchive?()
                    },
                    onNewMission: {
                        missionStore.archiveMission()
                        isCompletingAnimation = false
                        isAscendingToVault = false
                    }
                )
            }
        }
    }

    // ── Top Header Bar with Dual Pillars Switcher & Vault ──
    @ViewBuilder
    private var topHeaderBar: some View {
        VStack(spacing: 10) {
            // Brand & Vault Row
            HStack {
                Text("MILESTONE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(theme.accent)
                    .padding(.leading, 4)

                Spacer()

                Button {
                    HapticsManager.shared.impact(.light)
                    if !subscriptionStore.isProUser {
                        paywallFeature = .vault
                        showPaywallSheet = true
                    } else {
                        showVaultSheet = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 10, weight: .bold))
                        Text("VAULT")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.5)

                        if !subscriptionStore.isProUser {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color(red: 0.88, green: 0.76, blue: 0.44))
                        } else if !missionStore.vaultMissions.isEmpty {
                            Text("\(missionStore.vaultMissions.count)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(theme.background)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(theme.accent))
                        }
                    }
                    .foregroundStyle(isAscendingToVault ? theme.accent : theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isAscendingToVault ? theme.accent.opacity(0.18) : theme.surfaceLight.opacity(0.6))
                    )
                    .scaleEffect(vaultPulse)
                }
                .buttonStyle(.plain)
            }

            // Dual Pillars Segmented Selector Row
            pillarSwitcher
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // ── Dual Pillars Segmented Capsule Switcher ──
    @ViewBuilder
    private var pillarSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(MissionCategory.allCases, id: \.self) { category in
                let isSelected = missionStore.activePillar == category
                Button {
                    HapticsManager.shared.impact(.light)
                    if category == .personal && !subscriptionStore.isProUser {
                        paywallFeature = .dualMissions
                        showPaywallSheet = true
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            missionStore.switchPillar(to: category)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 10, weight: .bold))

                        Text(category.title)
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.2)
                            .lineLimit(1)

                        if category == .personal && !subscriptionStore.isProUser {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color(red: 0.88, green: 0.76, blue: 0.44))
                        }
                    }
                    .foregroundStyle(isSelected ? theme.background : theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Capsule())
                    .background(
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(category == .personal ? Color(red: 0.32, green: 0.72, blue: 0.53) : theme.accent)
                                    .matchedGeometryEffect(id: "activePillarCapsule", in: pillarNamespace)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(theme.surface.opacity(0.85))
        )
        .overlay(
            Capsule()
                .stroke(theme.border.opacity(0.35), lineWidth: 1)
        )
    }

    // ── Personal Pillar Empty Placeholder ──
    @ViewBuilder
    private var personalPillarEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            AliveLeafPulseView()

            VStack(spacing: 8) {
                Text("PERSONAL MISSION")
                    .font(.system(size: 11, weight: .black))
                    .tracking(3)
                    .foregroundStyle(Color(red: 0.32, green: 0.72, blue: 0.53))

                Text("Balance your ambition.")
                    .font(.system(size: 26, weight: .medium))
                    .tracking(-0.5)
                    .foregroundStyle(theme.textPrimary)

                Text("While your Work Mission drives career milestones, your Personal Mission guards health, study, or creative craft.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .lineSpacing(3)
            }

            Button {
                HapticsManager.shared.impact(.medium)
                if !subscriptionStore.isProUser {
                    paywallFeature = .dualMissions
                    showPaywallSheet = true
                } else {
                    showCreateMissionSheet = true
                }
            } label: {
                HStack(spacing: 8) {
                    if !subscriptionStore.isProUser {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.88, green: 0.76, blue: 0.44))
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                    }
                    Text("PLANT PERSONAL MISSION")
                        .font(.system(size: 12, weight: .black))
                        .tracking(2)
                }
                .foregroundStyle(theme.background)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.32, green: 0.72, blue: 0.53))
                )
                .shadow(color: Color(red: 0.32, green: 0.72, blue: 0.53).opacity(0.35), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 32)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
    }

    private func triggerCompletion(for mission: Mission) {
        // Capture snapshot before archiving
        activeMissionSnapshot = mission
        completedQuote = QuoteManager.randomQuote()

        // 1. Victory Haptic & Luxury Audio Chord
        HapticsManager.shared.notification(.success)
        AudioManager.shared.play(.missionComplete)

        // 2. Stage 1: Keystone 3D Spatial Lift & Radiant Emerald Bloom
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
            isCompletingAnimation = true
        }

        // 3. Stage 2: Ascension Glide upward into Vault Pill + Vault Reception Pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.40)) {
                isAscendingToVault = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.55)) {
                    vaultPulse = 1.18
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.20)) {
                    vaultPulse = 1.0
                }
            }
        }

        // 4. Stage 3: Apple Award Wax-Seal Celebration Sheet presentation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            showCelebrationSheet = true
        }
    }
}

/// Living, breathing botanical aura animation for the Personal Mission leaf icon
private struct AliveLeafPulseView: View {
    @State private var isBreathing: Bool = false
    @State private var innerPulse: Bool = false
    @State private var waveRipple: Bool = false

    private let emerald = Color(red: 0.32, green: 0.72, blue: 0.53)

    var body: some View {
        ZStack {
            // Ripple wave (expanding living botanical aura)
            Circle()
                .stroke(emerald.opacity(waveRipple ? 0.0 : 0.40), lineWidth: 1.5)
                .frame(width: 100, height: 100)
                .scaleEffect(waveRipple ? 1.6 : 0.88)

            // Outer radiant blooming halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            emerald.opacity(isBreathing ? 0.32 : 0.12),
                            emerald.opacity(isBreathing ? 0.10 : 0.02),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: isBreathing ? 75 : 45
                    )
                )
                .frame(width: 150, height: 150)

            // Inner vital core aura (more frequent organic cadence)
            Circle()
                .fill(emerald.opacity(innerPulse ? 0.28 : 0.10))
                .frame(width: 85, height: 85)
                .blur(radius: 14)
                .scaleEffect(innerPulse ? 1.18 : 0.90)

            // Organic Living Leaf icon with micro-sway and breathing scale
            Image(systemName: "leaf.fill")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(emerald)
                .scaleEffect(isBreathing ? 1.07 : 0.95)
                .rotationEffect(.degrees(isBreathing ? 2.5 : -2.0))
                .shadow(
                    color: emerald.opacity(isBreathing ? 0.70 : 0.30),
                    radius: isBreathing ? 16 : 6,
                    x: 0,
                    y: 0
                )
        }
        .frame(width: 160, height: 160)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                innerPulse = true
            }
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                waveRipple = true
            }
        }
    }
}
