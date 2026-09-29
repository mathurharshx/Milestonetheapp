import SwiftUI

public struct TasksTabView: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(PomodoroStore.self) private var pomodoroStore
    @Environment(UserStore.self) private var userStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme

    @Namespace private var pillarNamespace
    @State private var showPaywallSheet: Bool = false
    @State private var dailyInput: String = ""
    @State private var dailyHasTime: Bool = false
    @State private var dailyTime: Date = Date()
    @State private var editingTaskForTime: TodoTask? = nil
    @State private var editTimeDate: Date = Date()
    @State private var milestoneInput: String = ""
    @State private var isAddingDaily: Bool = false
    @State private var isAddingMilestone: Bool = false
    @State private var isMilestonesExpanded: Bool = true
    @State private var isCompletedMilestonesExpanded: Bool = false
    @State private var completingTaskIds: Set<String> = []
    @FocusState private var focusedInput: InputField?

    private enum InputField: Hashable {
        case daily
        case milestone
    }

    public init() {}

    private var currentMission: Mission? {
        missionStore.currentPillarMission
    }

    private var dailyTasks: [TodoTask] {
        currentMission?.todos.filter { $0.type == .daily } ?? []
    }

    private var activeMilestones: [TodoTask] {
        currentMission?.todos.filter { $0.type == .milestone && !$0.done } ?? []
    }

    private var completedMilestones: [TodoTask] {
        currentMission?.todos.filter { $0.type == .milestone && $0.done } ?? []
    }

    private var accentColor: Color {
        missionStore.activePillar == .personal ? AppColors.personalEmerald : theme.accent
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            // ── Atmospheric Alive Waves ──
            AliveDuneAtmosphereView(
                accentColor: accentColor,
                secondaryColor: missionStore.activePillar == .personal ? Color(red: 0x1A/255.0, green: 0x2E/255.0, blue: 0x22/255.0) : theme.surfaceLight,
                intensity: 0.70
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar & Pillar Switcher
                headerBar

                if let mission = currentMission {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // ── Mission Context Label ──
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("CURRENT MISSION")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(2.0)
                                        .foregroundStyle(theme.textTertiary)

                                    Text(mission.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(theme.textPrimary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                // Total progress indicator
                                let total = mission.todos.count
                                let done = mission.todos.filter { $0.type == .daily ? $0.isCompletedToday : $0.done }.count
                                if total > 0 {
                                    Text("\(done)/\(total)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(accentColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(accentColor.opacity(0.12)))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                            // ── 7-Day Consistency Ribbon ──
                            consistencyRibbon
                                .padding(.horizontal, 20)

                            // ── Daily Tasks Section ──
                            dailyTasksSection
                                .padding(.horizontal, 20)

                            // ── Milestone Deliverables Section ──
                            milestonesSection
                                .padding(.horizontal, 20)

                            Spacer(minLength: 88)
                        }
                        .padding(.top, 8)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 6)),
                        removal: .opacity
                    ))
                    .id(mission.id)
                } else {
                    emptyMissionState
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 6)),
                            removal: .opacity
                        ))
                        .id("empty_\(missionStore.activePillar.rawValue)")
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.8), value: missionStore.activePillar)
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallSheet(initialFeature: .dualMissions)
        }
        .onAppear {
            missionStore.checkAndResetDailyTasksIfNeeded()
        }
        .sheet(item: $editingTaskForTime) { task in
            VStack(spacing: 20) {
                HStack {
                    Text("SET REMINDER TIME")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2.0)
                        .foregroundStyle(theme.textSecondary)

                    Spacer()

                    Button {
                        editingTaskForTime = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                Text(task.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                DatePicker("Reminder Time", selection: $editTimeDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                HStack(spacing: 12) {
                    if task.reminderHour != nil {
                        Button(role: .destructive) {
                            HapticsManager.shared.impact(.light)
                            missionStore.updateTodoReminder(id: task.id, hour: nil, minute: nil)
                            editingTaskForTime = nil
                        } label: {
                            Text("REMOVE TIME")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(AppColors.danger)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.danger.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        HapticsManager.shared.impact(.medium)
                        let cal = Calendar.current
                        let hour = cal.component(.hour, from: editTimeDate)
                        let minute = cal.component(.minute, from: editTimeDate)
                        missionStore.updateTodoReminder(id: task.id, hour: hour, minute: minute)
                        editingTaskForTime = nil
                    } label: {
                        Text("SAVE")
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(1.4)
                            .foregroundStyle(theme.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accentColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
            .background(theme.background)
        }
    }

    // ── Header Bar ──
    @ViewBuilder
    private var headerBar: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MILESTONE")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(3.5)
                        .foregroundStyle(accentColor)

                    Text("Tasks")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                }

                Spacer()

                // Pillar Switcher Capsule
                HStack(spacing: 4) {
                    ForEach(MissionCategory.allCases, id: \.self) { cat in
                        let isSelected = missionStore.activePillar == cat
                        Button {
                            HapticsManager.shared.impact(.light)
                            if cat == .personal && !subscriptionStore.isProUser {
                                showPaywallSheet = true
                            } else {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                    missionStore.switchPillar(to: cat)
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 9, weight: .bold))

                                Text(cat.title)
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(1.4)
                                    .lineLimit(1)

                                if cat == .personal && !subscriptionStore.isProUser {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(Color(red: 0.88, green: 0.76, blue: 0.44))
                                }
                            }
                            .foregroundStyle(isSelected ? theme.background : theme.textSecondary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .contentShape(Capsule())
                            .background(
                                ZStack {
                                    if isSelected {
                                        Capsule()
                                            .fill(cat == .personal ? AppColors.personalEmerald : theme.accent)
                                            .matchedGeometryEffect(id: "tasksActivePillarCapsule", in: pillarNamespace)
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
                        .fill(theme.surfaceLight.opacity(0.8))
                        .overlay(Capsule().stroke(theme.border.opacity(0.4), lineWidth: 0.8))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 6)
        }
    }

    // ── 7-Day Consistency Ribbon ──
    @ViewBuilder
    private var consistencyRibbon: some View {
        let calendar = Calendar.current
        let today = Date()
        // Align with 7-day ribbon around today (-3 to +3)
        let daysOfWeek = (-3...3).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CONSISTENCY")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(2.0)
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                // Completed today count
                let dailyCount = dailyTasks.count
                let completedDailyCount = dailyTasks.filter { $0.isCompletedToday }.count
                if dailyCount > 0 {
                    Text("\(completedDailyCount) of \(dailyCount) today")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(completedDailyCount == dailyCount ? accentColor : theme.textSecondary)
                }
            }

            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { date in
                    let isToday = calendar.isDateInToday(date)
                    let dayLetter = shortDayLetter(for: date)
                    let dayNumber = calendar.component(.day, from: date)
                    let isCompletedDay = isToday && !dailyTasks.isEmpty && dailyTasks.allSatisfy { $0.isCompletedToday }

                    VStack(spacing: 6) {
                        Text(dayLetter)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isToday ? accentColor : theme.textTertiary)

                        ZStack {
                            Circle()
                                .fill(isToday ? accentColor.opacity(0.15) : theme.surfaceLight.opacity(0.4))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(isToday ? accentColor : Color.clear, lineWidth: 1.2)
                                )

                            if isCompletedDay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(accentColor)
                            } else {
                                Text("\(dayNumber)")
                                    .font(.system(size: 11, weight: isToday ? .bold : .medium, design: .monospaced))
                                    .foregroundStyle(isToday ? theme.textPrimary : theme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceLight.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.border.opacity(0.4), lineWidth: 1))
            )
        }
    }

    // ── Daily Tasks Section ──
    @ViewBuilder
    private var dailyTasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "repeat")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accentColor)

                    Text("DAILY TASKS")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2.0)
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                Button {
                    HapticsManager.shared.impact(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isAddingDaily.toggle()
                        if isAddingDaily {
                            focusedInput = .daily
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isAddingDaily ? "minus" : "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text(isAddingDaily ? "CANCEL" : "ADD DAILY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accentColor.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            // Inline Add Daily Input Row
            if isAddingDaily {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Circle()
                            .stroke(accentColor, lineWidth: 1.5)
                            .frame(width: 18, height: 18)

                        TextField("E.g., 10,000 steps, review metrics…", text: $dailyInput)
                            .font(.system(size: 15))
                            .foregroundStyle(theme.textPrimary)
                            .focused($focusedInput, equals: .daily)
                            .submitLabel(.done)
                            .onSubmit {
                                submitDailyTask()
                            }

                        if !dailyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button {
                                submitDailyTask()
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Optional Scheduled Time Toggle & Compact Picker
                    HStack(spacing: 8) {
                        Button {
                            HapticsManager.shared.impact(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dailyHasTime.toggle()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: dailyHasTime ? "bell.fill" : "bell")
                                    .font(.system(size: 10, weight: .bold))

                                Text(dailyHasTime ? "REMINDER TIME" : "+ ADD TIME")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .tracking(1.0)
                            }
                            .foregroundStyle(dailyHasTime ? accentColor : theme.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(dailyHasTime ? accentColor.opacity(0.14) : theme.surfaceLight.opacity(0.6))
                            )
                        }
                        .buttonStyle(.plain)

                        if dailyHasTime {
                            DatePicker("", selection: $dailyTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(accentColor)
                                .scaleEffect(0.88)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))

                            Spacer()

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dailyHasTime = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(theme.textTertiary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Spacer()
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.surfaceLight.opacity(0.85))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentColor.opacity(0.6), lineWidth: 1))
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
            }

            if dailyTasks.isEmpty && !isAddingDaily {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Text("No daily tasks scheduled")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                        Text("Add habits that repeat each day towards your goal")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textTertiary.opacity(0.8))
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.surfaceLight.opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.border.opacity(0.3), lineWidth: 1))
                )
                .transition(.identity)
            } else {
                VStack(spacing: 8) {
                    ForEach(dailyTasks) { task in
                        dailyTaskRow(task)
                            .transition(.asymmetric(insertion: .scale(scale: 0.98).combined(with: .opacity), removal: .opacity))
                    }
                }
            }
        }
    }

    // ── Daily Task Row ──
    @ViewBuilder
    private func dailyTaskRow(_ task: TodoTask) -> some View {
        let isDone = task.isCompletedToday
        let isCompleting = completingTaskIds.contains(task.id)

        HStack(spacing: 12) {
            // Generous 48pt tap target checkbox
            Button {
                guard !isCompleting else { return }
                if isDone {
                    // Instant uncheck with light impact
                    HapticsManager.shared.impact(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        missionStore.toggleTodo(id: task.id)
                    }
                } else {
                    // Option 2: Specular Sheen & Fold
                    HapticsManager.shared.impact(.light)
                    withAnimation(.easeOut(duration: 0.18)) {
                        completingTaskIds.insert(task.id)
                    }

                    // Celebratory pause (380ms) for sheen sweep to play, then success haptic & fold
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                        HapticsManager.shared.notification(.success)
                        withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
                            missionStore.toggleTodo(id: task.id)
                            completingTaskIds.remove(task.id)
                        }
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isDone || isCompleting ? accentColor : Color.clear)
                        .frame(width: 22, height: 22)

                    Circle()
                        .stroke(isDone || isCompleting ? accentColor : theme.textTertiary, lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isDone || isCompleting {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(theme.background)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Task Text & Optional Scheduled Time
            VStack(alignment: .leading, spacing: 3) {
                Text(task.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isDone || isCompleting ? theme.textTertiary : theme.textPrimary)
                    .strikethrough(isDone || isCompleting, color: theme.textTertiary)

                if let timeString = task.formattedReminderTime {
                    Button {
                        HapticsManager.shared.impact(.light)
                        var comps = DateComponents()
                        comps.hour = task.reminderHour ?? 9
                        comps.minute = task.reminderMinute ?? 0
                        editTimeDate = Calendar.current.date(from: comps) ?? Date()
                        editingTaskForTime = task
                    } label: {
                        HStack(spacing: 3.5) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 7.5))
                            Text(timeString)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }
                        .foregroundStyle(isDone ? theme.textTertiary.opacity(0.7) : accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isDone ? theme.surfaceLight.opacity(0.4) : accentColor.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Focus Action Button
            Button {
                HapticsManager.shared.impact(.medium)
                pomodoroStore.focusOn(taskId: task.id, taskTitle: task.text)
                userStore.selectedTab = .pomodoro
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 9, weight: .bold))
                    Text("FOCUS")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.0)
                }
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(theme.surfaceLight.opacity(0.8))
                        .overlay(Capsule().stroke(theme.border.opacity(0.5), lineWidth: 0.8))
                )
            }
            .buttonStyle(.plain)

            // Delete Button
            Button {
                HapticsManager.shared.impact(.light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    missionStore.deleteTodo(id: task.id)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textTertiary.opacity(0.6))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.surfaceLight.opacity(isCompleting ? 0.75 : 0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCompleting ? accentColor.opacity(0.65) : theme.border.opacity(0.4), lineWidth: isCompleting ? 1.2 : 0.8)
                )
                .overlay(
                    GeometryReader { geo in
                        if isCompleting {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.clear,
                                            accentColor.opacity(0.35),
                                            Color.white.opacity(0.45),
                                            accentColor.opacity(0.35),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.45)
                                .offset(x: isCompleting ? geo.size.width * 1.2 : -geo.size.width * 0.45)
                                .animation(.easeOut(duration: 0.38), value: isCompleting)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        )
    }

    // ── Milestone Deliverables Section ──
    @ViewBuilder
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flag")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accentColor)

                    Text("MILESTONES")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2.0)
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                Button {
                    HapticsManager.shared.impact(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isAddingMilestone.toggle()
                        if isAddingMilestone {
                            focusedInput = .milestone
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isAddingMilestone ? "minus" : "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text(isAddingMilestone ? "CANCEL" : "ADD MILESTONE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accentColor.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            // Inline Add Milestone Input Row
            if isAddingMilestone {
                HStack(spacing: 10) {
                    Circle()
                        .stroke(accentColor, lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    TextField("E.g., Complete chapter 1, finalize contract…", text: $milestoneInput)
                        .font(.system(size: 15))
                        .foregroundStyle(theme.textPrimary)
                        .focused($focusedInput, equals: .milestone)
                        .submitLabel(.done)
                        .onSubmit {
                            submitMilestoneTask()
                        }

                    if !milestoneInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            submitMilestoneTask()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.surfaceLight.opacity(0.85))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentColor.opacity(0.6), lineWidth: 1))
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
            }

            if activeMilestones.isEmpty && completedMilestones.isEmpty && !isAddingMilestone {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Text("No milestones set")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                        Text("Key deliverables to reach before the mission deadline")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textTertiary.opacity(0.8))
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.surfaceLight.opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.border.opacity(0.3), lineWidth: 1))
                )
                .transition(.identity)
            } else {
                VStack(spacing: 8) {
                    ForEach(activeMilestones) { task in
                        milestoneRow(task)
                            .transition(.asymmetric(insertion: .scale(scale: 0.98).combined(with: .opacity), removal: .opacity))
                    }
                }

                // Collapsible Completed Milestones
                if !completedMilestones.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            HapticsManager.shared.impact(.light)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isCompletedMilestonesExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isCompletedMilestonesExpanded ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(theme.textTertiary)

                                Text("COMPLETED (\(completedMilestones.count))")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundStyle(theme.textTertiary)

                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)

                        if isCompletedMilestonesExpanded {
                            VStack(spacing: 6) {
                                ForEach(completedMilestones) { task in
                                    milestoneRow(task)
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // ── Milestone Row ──
    @ViewBuilder
    private func milestoneRow(_ task: TodoTask) -> some View {
        let isCompleting = completingTaskIds.contains(task.id)

        HStack(spacing: 12) {
            Button {
                guard !isCompleting else { return }
                if task.done {
                    // Instant uncheck with light impact
                    HapticsManager.shared.impact(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        missionStore.toggleTodo(id: task.id)
                    }
                } else {
                    // Option 2: Specular Sheen & Fold
                    HapticsManager.shared.impact(.light)
                    withAnimation(.easeOut(duration: 0.18)) {
                        completingTaskIds.insert(task.id)
                    }

                    // Celebratory pause (380ms) for sheen sweep to play, then success haptic & fold
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                        HapticsManager.shared.notification(.success)
                        withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
                            missionStore.toggleTodo(id: task.id)
                            completingTaskIds.remove(task.id)
                        }
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(task.done || isCompleting ? accentColor : Color.clear)
                        .frame(width: 22, height: 22)

                    Circle()
                        .stroke(task.done || isCompleting ? accentColor : theme.textTertiary, lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if task.done || isCompleting {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(theme.background)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(task.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(task.done || isCompleting ? theme.textTertiary : theme.textPrimary)
                .strikethrough(task.done || isCompleting, color: theme.textTertiary)

            Spacer()

            if !task.done && !isCompleting {
                Button {
                    HapticsManager.shared.impact(.medium)
                    pomodoroStore.focusOn(taskId: task.id, taskTitle: task.text)
                    userStore.selectedTab = .pomodoro
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 9, weight: .bold))
                        Text("FOCUS")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.0)
                    }
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(theme.surfaceLight.opacity(0.8))
                            .overlay(Capsule().stroke(theme.border.opacity(0.5), lineWidth: 0.8))
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                HapticsManager.shared.impact(.light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    missionStore.deleteTodo(id: task.id)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textTertiary.opacity(0.6))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.surfaceLight.opacity(isCompleting ? 0.75 : 0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCompleting ? accentColor.opacity(0.65) : theme.border.opacity(0.4), lineWidth: isCompleting ? 1.2 : 0.8)
                )
                .overlay(
                    GeometryReader { geo in
                        if isCompleting {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.clear,
                                            accentColor.opacity(0.35),
                                            Color.white.opacity(0.45),
                                            accentColor.opacity(0.35),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.45)
                                .offset(x: isCompleting ? geo.size.width * 1.2 : -geo.size.width * 0.45)
                                .animation(.easeOut(duration: 0.38), value: isCompleting)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        )
    }

    // ── Empty Mission State ──
    @ViewBuilder
    private var emptyMissionState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(theme.textTertiary)

            Text("No Active Mission")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            Text("Define your mission in the Mission tab to start organizing daily tasks and deliverables.")
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                HapticsManager.shared.impact(.light)
                userStore.selectedTab = .mission
            } label: {
                Text("GO TO MISSION")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(theme.background)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(accentColor)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
        }
    }

    // ── Helper Actions ──
    private func submitDailyTask() {
        let trimmed = dailyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        HapticsManager.shared.impact(.light)
        let cal = Calendar.current
        let hour = dailyHasTime ? cal.component(.hour, from: dailyTime) : nil
        let minute = dailyHasTime ? cal.component(.minute, from: dailyTime) : nil
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            missionStore.addTodo(text: trimmed, type: .daily, reminderHour: hour, reminderMinute: minute)
            dailyInput = ""
            dailyHasTime = false
        }
    }

    private func submitMilestoneTask() {
        let trimmed = milestoneInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        HapticsManager.shared.impact(.light)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            missionStore.addTodo(text: trimmed, type: .milestone)
            milestoneInput = ""
        }
    }

    private func shortDayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter day (M, T, W, T, F, S, S)
        return formatter.string(from: date).uppercased()
    }
}
