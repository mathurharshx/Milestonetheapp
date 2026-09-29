import SwiftUI

public struct CreateMissionSheet: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywallSheet: Bool = false
    @State private var title: String = ""
    @State private var targetDate: Date = {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(86400))
        comps.hour = 23
        comps.minute = 59
        comps.second = 59
        return Calendar.current.date(from: comps) ?? Date().addingTimeInterval(86400)
    }()
    @State private var hasTime: Bool = false
    @State private var isDatePickerExpanded: Bool = false
    @State private var isTimePickerExpanded: Bool = false
    @State private var todos: [TodoTask] = []
    @State private var taskTypeSelection: TaskType = .milestone
    @State private var dailyTaskHasTime: Bool = false
    @State private var dailyTaskTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    private enum Field: Hashable {
        case title
        case taskInput
    }

    @FocusState private var focusedField: Field?
    @State private var todoInput: String = ""
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    public var category: MissionCategory? = nil
    public var isEmbedded: Bool = false

    // Alive Living Border & Button State
    @State private var isHeroBreathing: Bool = false
    @State private var heroBorderAngle: Double = 0.0
    @State private var isButtonBreathing: Bool = false

    // Monolith Forge Laser Ignition State
    @State private var isForging: Bool = false
    @State private var forgeLaserProgress: CGFloat = 0.0

    private var effectiveCategory: MissionCategory {
        category ?? missionStore.activePillar
    }

    private var accentColor: Color {
        effectiveCategory == .personal ? AppColors.personalEmerald : theme.accent
    }

    public init(category: MissionCategory? = nil, isEmbedded: Bool = false) {
        self.category = category
        self.isEmbedded = isEmbedded
    }

    private var isReady: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.string(from: targetDate)
    }

    private var formattedTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: targetDate)
    }

    public var body: some View {
        Group {
            if isEmbedded {
                formContent
            } else {
                NavigationStack {
                    ZStack {
                        // ── Living Atmosphere ──
                        AliveDuneAtmosphereView(
                            accentColor: accentColor,
                            secondaryColor: effectiveCategory == .personal ? Color(red: 0x1A/255.0, green: 0x2E/255.0, blue: 0x22/255.0) : theme.surfaceLight,
                            intensity: 0.70
                        )
                        .ignoresSafeArea()

                        formContent
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallSheet(initialFeature: .dualMissions)
        }
        .onAppear {
            isHeroBreathing = true
            heroBorderAngle = 360
            isButtonBreathing = true
        }
    }

    @ViewBuilder
    private var formContent: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                // ── Scrollable Form Area ──
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        // Header
                        VStack(alignment: .center, spacing: 8) {
                            Text(category == .personal ? "New Personal Mission" : "New Mission")
                                .font(.system(size: 32, weight: .semibold))
                                .tracking(-0.6)
                                .foregroundStyle(theme.textPrimary)
                                .multilineTextAlignment(.center)

                            ZStack {
                                Text(category == .personal ? "Guard your health, craft, and clarity." : "One goal at a time.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(theme.textSecondary)
                                    .multilineTextAlignment(.center)

#if DEBUG
                                HStack {
                                    Spacer()

                                    Button {
                                        HapticsManager.shared.impact(.light)
                                        title = "Scale to $100k ARR"
                                        todos = [
                                            TodoTask(id: "1", text: "Reach out to 5 enterprise leads", done: false, type: .daily, reminderHour: 8, reminderMinute: 30),
                                            TodoTask(id: "2", text: "Review churn and activation metrics", done: false, type: .daily, reminderHour: 17, reminderMinute: 0),
                                            TodoTask(id: "3", text: "Finalize enterprise pricing tier", done: false, type: .milestone),
                                            TodoTask(id: "4", text: "Close pilot agreements with 3 design partners", done: false, type: .milestone),
                                            TodoTask(id: "5", text: "Deploy self-serve checkout & billing flow", done: false, type: .milestone)
                                        ]
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "wand.and.stars")
                                            Text("DEMO FILL")
                                        }
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1)
                                        .foregroundStyle(theme.accent)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(theme.accentDim))
                                    }
                                    .buttonStyle(.plain)
                                }
#endif
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 20)

                        // 1. HERO SECTION: TITLE (REQUIRED)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Text("AWAITING MISSION")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(theme.textSecondary)

                                Text("REQUIRED")
                                    .font(.system(size: 9, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(accentColor)

                                Spacer()

                                if !title.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(accentColor)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }

                            // Sleek, compact single-row mission title text field
                            TextField("Define your mission", text: $title)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(theme.textPrimary)
                                .focused($focusedField, equals: .title)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = nil
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    ZStack {
                                        // Deep glass base
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(theme.surfaceLight.opacity(0.6))

                                        // Living Inner Ambient Radial Aura
                                        RadialGradient(
                                            colors: [
                                                accentColor.opacity(isHeroBreathing ? (title.isEmpty ? 0.08 : 0.04) : 0.01),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 100
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                )
                                .overlay(
                                    // Outer Soft Ambient Glowing Bloom
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            accentColor.opacity(isHeroBreathing ? (focusedField == .title || title.isEmpty ? 0.35 : 0.18) : 0.08),
                                            lineWidth: isHeroBreathing ? 2.2 : 1.2
                                        )
                                        .blur(radius: isHeroBreathing ? 5 : 2)
                                )
                                .overlay(
                                    // Sharp Living Sweeping Gradient Border
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            AngularGradient(
                                                gradient: Gradient(colors: [
                                                    accentColor.opacity(0.85),
                                                    accentColor.opacity(0.18),
                                                    accentColor.opacity(0.75),
                                                    accentColor.opacity(0.12),
                                                    accentColor.opacity(0.85)
                                                ]),
                                                center: .center,
                                                angle: .degrees(heroBorderAngle)
                                            ),
                                            lineWidth: isForging ? 2.0 : (focusedField == .title ? 1.4 : 1.0)
                                        )
                                )
                                .overlay(
                                    // Monolith Forge High-Luminance Laser Ignition Line
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .trim(from: 0, to: forgeLaserProgress)
                                        .stroke(
                                            LinearGradient(
                                                colors: [accentColor, Color.white, accentColor],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                                        )
                                        .opacity(isForging ? 1.0 : 0.0)
                                )
                                .scaleEffect(isForging ? 1.02 : 1.0)
                                .animation(.spring(response: 0.32, dampingFraction: 0.68), value: isForging)
                                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isHeroBreathing)
                                .animation(.linear(duration: 6.0).repeatForever(autoreverses: false), value: heroBorderAngle)
                                .disabled(isForging)
                        }

                        // 2. TARGET DATE (REQUIRED)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Text("TARGET DATE")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(theme.textSecondary)

                                Text("REQUIRED")
                                    .font(.system(size: 9, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(theme.accent)
                            }

                            Button {
                                HapticsManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isDatePickerExpanded.toggle()
                                    if isDatePickerExpanded {
                                        isTimePickerExpanded = false
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(theme.accent)

                                    Text(formattedDateString)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(theme.textPrimary)

                                    Spacer()

                                    Image(systemName: isDatePickerExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(theme.textTertiary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(theme.surfaceLight.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isDatePickerExpanded ? theme.accent : theme.border.opacity(0.6), lineWidth: isDatePickerExpanded ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if isDatePickerExpanded {
                                VStack(spacing: 0) {
                                    DatePicker(
                                        "",
                                        selection: $targetDate,
                                        in: Date()...,
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(.graphical)
                                    .tint(theme.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 4)

                                    Button {
                                        HapticsManager.shared.impact(.light)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            isDatePickerExpanded = false
                                        }
                                    } label: {
                                        Text("DONE")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(2)
                                            .foregroundStyle(theme.accent)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                    }
                                }
                                .padding(.bottom, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(theme.surfaceLight.opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.border.opacity(0.5), lineWidth: 1)
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }

                        // 3. TARGET TIME (OPTIONAL TOGGLE)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                HStack(spacing: 4) {
                                    Text("SPECIFIC TIME")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(2)
                                        .foregroundStyle(theme.textSecondary)

                                    Text("OPTIONAL")
                                        .font(.system(size: 9, weight: .regular))
                                        .tracking(1.5)
                                        .foregroundStyle(theme.textTertiary)
                                }

                                Spacer()

                                Toggle("", isOn: $hasTime)
                                    .labelsHidden()
                                    .tint(theme.accent)
                                    .onChange(of: hasTime) { _, newValue in
                                        HapticsManager.shared.impact(.light)
                                        if !newValue {
                                            isTimePickerExpanded = false
                                            var comps = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
                                            comps.hour = 23
                                            comps.minute = 59
                                            comps.second = 59
                                            targetDate = Calendar.current.date(from: comps) ?? targetDate
                                        }
                                    }
                            }

                            if hasTime {
                                Button {
                                    HapticsManager.shared.impact(.light)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        isTimePickerExpanded.toggle()
                                        if isTimePickerExpanded {
                                            isDatePickerExpanded = false
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(theme.accent)

                                        Text(formattedTimeString)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(theme.textPrimary)

                                        Spacer()

                                        Image(systemName: isTimePickerExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(theme.textTertiary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(theme.surfaceLight.opacity(0.6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isTimePickerExpanded ? theme.accent : theme.border.opacity(0.6), lineWidth: isTimePickerExpanded ? 1.5 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity.combined(with: .move(edge: .top)))

                                if isTimePickerExpanded {
                                    VStack(spacing: 0) {
                                        DatePicker(
                                            "",
                                            selection: $targetDate,
                                            displayedComponents: [.hourAndMinute]
                                        )
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .tint(theme.accent)
                                        .frame(maxWidth: .infinity)

                                        Button {
                                            HapticsManager.shared.impact(.light)
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                isTimePickerExpanded = false
                                            }
                                        } label: {
                                            Text("DONE")
                                                .font(.system(size: 11, weight: .bold))
                                                .tracking(2)
                                                .foregroundStyle(theme.accent)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.top, 4)
                                    .padding(.bottom, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(theme.surfaceLight.opacity(0.4))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(theme.border.opacity(0.5), lineWidth: 1)
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }

                        // 4. TASKS (OPTIONAL)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Text("TASKS & DELIVERABLES")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(theme.textSecondary)

                                Text("OPTIONAL")
                                    .font(.system(size: 9, weight: .regular))
                                    .tracking(1.5)
                                    .foregroundStyle(theme.textTertiary)
                            }

                            // Type Selector Capsule
                            HStack(spacing: 4) {
                                Button {
                                    HapticsManager.shared.impact(.light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        taskTypeSelection = .milestone
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flag")
                                            .font(.system(size: 9, weight: .bold))
                                        Text("MILESTONE")
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(1.2)
                                    }
                                    .foregroundStyle(taskTypeSelection == .milestone ? theme.background : theme.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule().fill(taskTypeSelection == .milestone ? accentColor : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    HapticsManager.shared.impact(.light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        taskTypeSelection = .daily
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "repeat")
                                            .font(.system(size: 9, weight: .bold))
                                        Text("DAILY TASK")
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(1.2)
                                    }
                                    .foregroundStyle(taskTypeSelection == .daily ? theme.background : theme.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule().fill(taskTypeSelection == .daily ? accentColor : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(3)
                            .background(
                                Capsule()
                                    .fill(theme.surfaceLight.opacity(0.6))
                                    .overlay(Capsule().stroke(theme.border.opacity(0.4), lineWidth: 0.8))
                            )
                            .padding(.bottom, 2)

                            VStack(spacing: 8) {
                                // Existing Tasks
                                ForEach(todos) { task in
                                    HStack(spacing: 10) {
                                        Image(systemName: task.type == .daily ? "repeat" : "flag")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(accentColor)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(task.text)
                                                .font(.system(size: 15))
                                                .foregroundStyle(theme.textPrimary)

                                            if let timeStr = task.formattedReminderTime {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "bell.fill")
                                                        .font(.system(size: 8))
                                                    Text(timeStr)
                                                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                                }
                                                .foregroundStyle(accentColor.opacity(0.85))
                                            }
                                        }

                                        Spacer()

                                        Text(task.type == .daily ? "DAILY" : "MILESTONE")
                                            .font(.system(size: 8.5, weight: .heavy))
                                            .tracking(1.0)
                                            .foregroundStyle(theme.textTertiary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(theme.surfaceLight))

                                        Button {
                                            todos.removeAll(where: { $0.id == task.id })
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12))
                                                .foregroundStyle(theme.textTertiary)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(theme.surfaceLight.opacity(0.4))
                                    )
                                    .transition(.asymmetric(insertion: .scale(scale: 0.98).combined(with: .opacity), removal: .opacity))
                                }

                                // Add Task Row
                                HStack(spacing: 12) {
                                    Circle()
                                        .stroke(theme.textTertiary, lineWidth: 1)
                                        .frame(width: 6, height: 6)

                                    TextField(taskTypeSelection == .daily ? "Add daily habit (e.g. 10k steps)…" : "Add milestone deliverable…", text: $todoInput)
                                        .font(.system(size: 15))
                                        .foregroundStyle(theme.textPrimary)
                                        .focused($focusedField, equals: .taskInput)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            let trimmed = todoInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                            if trimmed.isEmpty {
                                                focusedField = nil
                                            } else {
                                                addTodo(proxy: proxy)
                                            }
                                        }

                                    if !todoInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Button {
                                            addTodo(proxy: proxy)
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(accentColor)
                                        }
                                    }
                                }
                                .id("taskInputRow")
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.surfaceLight.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .taskInput ? accentColor : theme.border.opacity(0.5), lineWidth: focusedField == .taskInput ? 1.5 : 1)
                                )

                                if taskTypeSelection == .daily {
                                    HStack(spacing: 8) {
                                        Button {
                                            HapticsManager.shared.impact(.light)
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                dailyTaskHasTime.toggle()
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: dailyTaskHasTime ? "bell.fill" : "bell")
                                                    .font(.system(size: 10, weight: .bold))

                                                Text(dailyTaskHasTime ? "REMINDER TIME" : "+ ADD TIME")
                                                    .font(.system(size: 9.5, weight: .bold))
                                                    .tracking(1.0)
                                            }
                                            .foregroundStyle(dailyTaskHasTime ? accentColor : theme.textTertiary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(dailyTaskHasTime ? accentColor.opacity(0.14) : theme.surfaceLight.opacity(0.6))
                                            )
                                        }
                                        .buttonStyle(.plain)

                                        if dailyTaskHasTime {
                                            DatePicker("", selection: $dailyTaskTime, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .tint(accentColor)
                                                .scaleEffect(0.88)
                                                .transition(.opacity.combined(with: .scale(scale: 0.95)))

                                            Spacer()

                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    dailyTaskHasTime = false
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
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focusedField) { _, newField in
                    if newField == .taskInput {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("taskInputRow", anchor: .bottom)
                            }
                        }
                    }
                }

                // ── Bottom Action (BEGIN MISSION) ──
                VStack(spacing: 0) {
                    Button {
                        handleSubmit()
                    } label: {
                        HStack(spacing: 8) {
                            Text("BEGIN MISSION")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(3)

                            if isReady {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                        .foregroundStyle(isReady ? theme.background : theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isReady ? accentColor : theme.surfaceLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isReady
                                        ? Color.white.opacity(0.18)
                                        : accentColor.opacity(isButtonBreathing ? 0.22 : 0.08),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isReady
                                ? accentColor.opacity(isButtonBreathing ? 0.45 : 0.18)
                                : accentColor.opacity(isButtonBreathing ? 0.14 : 0.03),
                            radius: isReady ? (isButtonBreathing ? 14 : 7) : (isButtonBreathing ? 8 : 4),
                            x: 0,
                            y: isReady ? 3 : 1
                        )
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isButtonBreathing)
                    }
                    .disabled(!isReady)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .background(Color.clear)
            }
        }
    }

    private func addTodo(proxy: ScrollViewProxy? = nil) {
        let text = todoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        HapticsManager.shared.impact(.light)
        let hour = (taskTypeSelection == .daily && dailyTaskHasTime) ? Calendar.current.component(.hour, from: dailyTaskTime) : nil
        let minute = (taskTypeSelection == .daily && dailyTaskHasTime) ? Calendar.current.component(.minute, from: dailyTaskTime) : nil
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            todos.append(TodoTask(text: text, type: taskTypeSelection, reminderHour: hour, reminderMinute: minute))
            todoInput = ""
            dailyTaskHasTime = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy?.scrollTo("taskInputRow", anchor: .bottom)
            }
        }
    }

    private func handleSubmit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            alertTitle = "Missing Title"
            alertMessage = "Please enter a mission title."
            showAlert = true
            return
        }

        let now = Date()
        let isToday = Calendar.current.isDateInToday(targetDate)

        if isToday && !hasTime {
            HapticsManager.shared.notification(.error)
            alertTitle = "Time Required"
            alertMessage = "Since this mission is for today, please add a specific target time."
            showAlert = true
            return
        }

        if targetDate <= now {
            HapticsManager.shared.notification(.error)
            alertTitle = "Invalid Time"
            alertMessage = "Your target time must be in the future."
            showAlert = true
            return
        }

        let effectiveCategory = category ?? missionStore.activePillar
        if effectiveCategory == .personal && !subscriptionStore.isProUser {
            showPaywallSheet = true
            return
        }

        // ── Phase 1: The Monolith Forge Pressure-Lock & Sound ──
        focusedField = nil
        isForging = true
        HapticsManager.shared.impact(.heavy)
        AudioManager.shared.play(.missionStart)

        // Rapid laser stroke ignition around title card
        withAnimation(.easeOut(duration: 0.28)) {
            forgeLaserProgress = 1.0
        }

        // Secondary confirmation micro-impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            HapticsManager.shared.impact(.rigid)
        }

        // ── Phase 2: State Persistence & Seamless Home Screen Hand-Off ──
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            missionStore.createMission(
                title: trimmedTitle,
                targetDate: targetDate,
                note: nil,
                todos: todos,
                category: effectiveCategory
            )

            // Trigger home screen Monolith Matrix Cascade
            MissionLaunchCoordinator.shared.triggerLaunch(category: effectiveCategory)

            dismiss()
        }
    }
}
