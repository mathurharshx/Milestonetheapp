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
    @State private var isConfirmingCompletion: Bool = false
    @State private var resetTimer: Timer? = nil

    @Namespace private var pillarNamespace

    public init(onNavigateToArchive: (() -> Void)? = nil) {
        self.onNavigateToArchive = onNavigateToArchive
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            // ── Atmospheric Alive Waves ──
            AliveDuneAtmosphereView(
                accentColor: missionStore.activePillar == .personal ? AppColors.personalEmerald : theme.accent,
                secondaryColor: missionStore.activePillar == .personal ? Color(red: 0x1A/255.0, green: 0x2E/255.0, blue: 0x22/255.0) : theme.surfaceLight,
                intensity: 0.75
            )
            .ignoresSafeArea()

            let displayedMission = missionStore.currentPillarMission ?? (isCompletingAnimation ? activeMissionSnapshot : nil)

            if let mission = displayedMission {
                VStack(spacing: 0) {
                    // ── Top Brand, Dual Pillars & Vault Header ──
                    topHeaderBar

                    // ── Pinned Keystone Hero Card ──
                    KeystoneCardView(
                        event: keystoneEvent,
                        isCompleting: isCompletingAnimation,
                        isAscending: isAscendingToVault,
                        missionCategory: mission.category
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

                        // ── High-Performance Isolated 1-Second Countdown & Dot Matrix ──
                        TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                            let countdown = DateCalculations.calculateFullCountdown(
                                createdAt: mission.createdAt,
                                targetDate: mission.targetDate
                            )

                            // Countdown Timer
                            CountdownTimerView(countdown: countdown)

                            // Dot Grid Matrix with Completion Glow Wave (<48h / <24h runway tracks)
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                        // ── Scrollable Tasks (Only Tasks Scroll, Dimmed during celebration) ──
                        ScrollView(showsIndicators: false) {
                            MissionTodoListView(
                                todos: mission.todos,
                                onToggle: { id in
                                    let willBeDone = !(mission.todos.first(where: { $0.id == id })?.done ?? true)
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                        missionStore.toggleTodo(id: id)
                                    }
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
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                        missionStore.deleteTodo(id: id)
                                    }
                                    keystoneEvent = .taskDeleted
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                        if keystoneEvent == .taskDeleted {
                                            keystoneEvent = .none
                                        }
                                    }
                                },
                                onMove: { indices, newOffset in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        missionStore.moveTodo(fromOffsets: indices, toOffset: newOffset)
                                    }
                                },
                                onAddTask: { text in
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                        missionStore.addTodo(text: text)
                                    }
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
                            .padding(.bottom, 24)
                        }
                        .scrollIndicators(.hidden)
                        .padding(.horizontal, 24)
                        .opacity(isCompletingAnimation ? 0.35 : 1.0)
                        .disabled(isCompletingAnimation)
                        .animation(.easeInOut(duration: 0.3), value: isCompletingAnimation)

                        // ── Pinned Bottom Action (Morphing Anti-Misclick Split Button) ──
                        VStack(spacing: 0) {
                            if isCompletingAnimation {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 13, weight: .bold))

                                    Text("MISSION ACCOMPLISHED")
                                        .font(.system(size: 11, weight: .black))
                                        .tracking(2.0)
                                }
                                .foregroundStyle(mission.category == .personal ? AppColors.personalEmerald : theme.accent)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill((mission.category == .personal ? AppColors.personalEmerald : theme.accent).opacity(0.12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke((mission.category == .personal ? AppColors.personalEmerald : theme.accent).opacity(0.3), lineWidth: 1)
                                )
                                .transition(.opacity)
                            } else if isConfirmingCompletion {
                                HStack(spacing: 10) {
                                    // Cancel Pill (~35% width)
                                    Button {
                                        HapticsManager.shared.impact(.light)
                                        resetTimer?.invalidate()
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                            isConfirmingCompletion = false
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 11, weight: .black))
                                            Text("CANCEL")
                                                .font(.system(size: 11, weight: .black))
                                                .tracking(1.4)
                                        }
                                        .foregroundStyle(theme.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(theme.surfaceLight.opacity(0.85))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(theme.border.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                    .frame(width: 115)

                                    // Confirm Complete Pill (~65% width)
                                    Button {
                                        resetTimer?.invalidate()
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                            isConfirmingCompletion = false
                                        }
                                        triggerCompletion(for: mission)
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text("CONFIRM COMPLETE")
                                                .font(.system(size: 12, weight: .heavy))
                                                .tracking(1.6)

                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .black))
                                        }
                                        .foregroundStyle(theme.background)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(mission.category == .personal ? AppColors.personalEmerald : theme.accent)
                                        )
                                        .shadow(
                                            color: (mission.category == .personal ? AppColors.personalEmerald : theme.accent).opacity(0.4),
                                            radius: 10,
                                            x: 0,
                                            y: 4
                                        )
                                    }
                                }
                                .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
                            } else {
                                Button {
                                    HapticsManager.shared.impact(.medium)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        isConfirmingCompletion = true
                                    }
                                    resetTimer?.invalidate()
                                    resetTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { _ in
                                        DispatchQueue.main.async {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                isConfirmingCompletion = false
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.seal")
                                            .font(.system(size: 16, weight: .bold))

                                        Text("MARK COMPLETE")
                                            .font(.system(size: 13, weight: .bold))
                                            .tracking(2.5)
                                    }
                                    .foregroundStyle(mission.category == .personal ? AppColors.personalEmerald : theme.accent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(mission.category == .personal ? AppColors.personalEmerald : theme.accent, lineWidth: 1.5)
                                    )
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 12)
                        .background(Color.clear)
                    }
                } else {
                VStack(spacing: 0) {
                    topHeaderBar

                    if missionStore.activePillar == .personal {
                        personalPillarEmptyState
                    } else {
                        // Work Mission direct creation view
                        CreateMissionSheet(category: .work, isEmbedded: true)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallSheet(initialFeature: paywallFeature)
        }
        .fullScreenCover(isPresented: $showCelebrationSheet, onDismiss: {
            isCompletingAnimation = false
            isAscendingToVault = false
            activeMissionSnapshot = nil
        }) {
            if let mission = activeMissionSnapshot ?? missionStore.currentPillarMission {
                MissionCelebrationSheet(
                    mission: mission,
                    quote: completedQuote,
                    onArchive: {
                        missionStore.archiveMission(mission)
                        isCompletingAnimation = false
                        isAscendingToVault = false
                        activeMissionSnapshot = nil
                        onNavigateToArchive?()
                    },
                    onNewMission: {
                        missionStore.archiveMission(mission)
                        isCompletingAnimation = false
                        isAscendingToVault = false
                        activeMissionSnapshot = nil
                        showCreateMissionSheet = true
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
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(3.5)
                    .foregroundStyle(theme.accent)

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
                .sheet(isPresented: $showVaultSheet) {
                    VaultSheet()
                }
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
                                    .fill(category == .personal ? AppColors.personalEmerald : theme.accent)
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
                    .foregroundStyle(AppColors.personalEmerald)

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
                        .fill(AppColors.personalEmerald)
                )
                .shadow(color: AppColors.personalEmerald.opacity(0.35), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 32)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCreateMissionSheet) {
                CreateMissionSheet(category: .personal)
            }
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
    }

    private func triggerCompletion(for mission: Mission) {
        guard !isCompletingAnimation else { return }

        // 1. Capture snapshot before archiving so CelebrationSheet has all data
        activeMissionSnapshot = mission
        completedQuote = QuoteManager.randomQuote()

        // 2. Victory Haptic & Luxury Audio Chord
        HapticsManager.shared.notification(.success)
        AudioManager.shared.play(.missionComplete)

        // 3. Stage 1: Keystone 3D Spatial Lift & Radiant Bloom
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
            isCompletingAnimation = true
        }

        // 4. Stage 2: Ascension Glide upward into Vault Pill + Vault Reception Pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.40)) {
                isAscendingToVault = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.55)) {
                    vaultPulse = 1.25
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.20)) {
                    vaultPulse = 1.0
                }
            }
        }

        // 5. Stage 3: Apple Award Wax-Seal Celebration Sheet presentation
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

    private let emerald = AppColors.personalEmerald

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
