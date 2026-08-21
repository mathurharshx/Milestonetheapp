import SwiftUI

public struct MissionTabView: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(\.theme) private var theme

    public var onNavigateToArchive: (() -> Void)?

    @State private var isCompletingAnimation: Bool = false
    @State private var showCelebrationSheet: Bool = false
    @State private var completedQuote: Quote?
    @State private var activeMissionSnapshot: Mission?

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

                    ScrollView {
                        VStack(spacing: 28) {
                            // Top Brand
                            HStack {
                                Text("MILESTONE")
                                    .font(.system(size: 11, weight: .heavy))
                                    .tracking(4)
                                    .foregroundStyle(theme.accent)
                                    .padding(.leading, 4)

                                Spacer()
                            }
                            .padding(.top, 24)

                            // Mission Title & Note
                            VStack(spacing: 8) {
                                Text(mission.title)
                                    .font(.system(size: 32, weight: .medium))
                                    .tracking(-0.6)
                                    .foregroundStyle(theme.textPrimary)
                                    .multilineTextAlignment(.center)

                                if let note = mission.note, !note.isEmpty {
                                    Text(note)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(theme.textTertiary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.horizontal, 16)

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
                            .padding(.vertical, 8)

                            // To-Do List (Swipe to Complete / Delete & Priority Reordering)
                            MissionTodoListView(
                                todos: mission.todos,
                                onToggle: { id in
                                    missionStore.toggleTodo(id: id)
                                },
                                onDelete: { id in
                                    missionStore.deleteTodo(id: id)
                                },
                                onMove: { indices, newOffset in
                                    missionStore.moveTodo(fromOffsets: indices, toOffset: newOffset)
                                },
                                onAddTask: { text in
                                    missionStore.addTodo(text: text)
                                }
                            )

                            // Apple-Style Mark Complete Action Button
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
                                .frame(height: 54)
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
                            .padding(.top, 24)
                            .padding(.bottom, 48)
                        }
                        .padding(.horizontal, 24)
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
