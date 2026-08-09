import SwiftUI

public struct MissionTabView: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(\.theme) private var theme

    @State private var showCompleteConfirmation: Bool = false
    @State private var showQuoteModal: Bool = false
    @State private var completedQuote: Quote?

    public init() {}

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
                        VStack(spacing: 24) {
                            // Top Brand
                            HStack {
                                Text("MILESTONE")
                                    .font(.system(size: 11, weight: .heavy))
                                    .tracking(4)
                                    .foregroundStyle(theme.accent)
                                    .padding(.leading, 4)

                                Spacer()
                            }
                            .padding(.top, 16)

                            // Mission Title & Note
                            VStack(spacing: 8) {
                                Text(mission.title)
                                    .font(.system(size: 28, weight: .medium))
                                    .tracking(-0.5)
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

                            // Dot Grid Matrix
                            DotGridView(
                                totalDays: countdown.totalDays,
                                daysElapsed: countdown.daysElapsed,
                                totalHours: countdown.totalHours,
                                hoursElapsed: countdown.hoursElapsed,
                                isUnder24h: countdown.isUnder24h
                            )
                            .padding(.vertical, 8)

                            // To-Do List
                            MissionTodoListView(
                                todos: mission.todos,
                                onToggle: { id in
                                    missionStore.toggleTodo(id: id)
                                },
                                onAddTask: { text in
                                    missionStore.addTodo(text: text)
                                }
                            )

                            // Mark Complete Button
                            Button {
                                showCompleteConfirmation = true
                            } label: {
                                Text("MARK COMPLETE")
                                    .font(.system(size: 13, weight: .semibold))
                                    .tracking(3)
                                    .foregroundStyle(theme.accent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.accent, lineWidth: 1)
                                    )
                            }
                            .padding(.top, 32)
                            .padding(.bottom, 24)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            } else {
                // No active mission -> Direct creation view
                CreateMissionSheet()
            }

            // Completion Quote Modal Overlay
            if showQuoteModal {
                QuoteModalView(quote: completedQuote) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showQuoteModal = false
                        missionStore.archiveMission()
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .confirmationDialog(
            "Complete Mission",
            isPresented: $showCompleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Complete") {
                HapticsManager.shared.notification(.success)
                missionStore.completeMission()
                completedQuote = QuoteManager.randomQuote()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showQuoteModal = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark this mission as complete?")
        }
    }
}
