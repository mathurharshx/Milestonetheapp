import SwiftUI

public struct CreateMissionSheet: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

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
    @State private var todoInput: String = ""
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    public init() {}

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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MILESTONE")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(4)
                            .foregroundStyle(theme.accent)
                            .padding(.leading, 2)

                        Text("New Mission")
                            .font(.system(size: 34, weight: .medium))
                            .tracking(-0.8)
                            .foregroundStyle(theme.textPrimary)

                        Text("One goal at a time.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(.top, 28)

                    // 1. TITLE (REQUIRED)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("TITLE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(theme.textSecondary)

                            Text("REQUIRED")
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(1.5)
                                .foregroundStyle(theme.accent)
                        }

                        TextField("Define your mission", text: $title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(theme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(theme.surfaceLight.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(theme.border.opacity(0.6), lineWidth: 1)
                            )
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
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .tint(theme.accent)
                                .frame(maxWidth: .infinity)

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

                    // 3. TARGET TIME (OPTIONAL)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 4) {
                                Text("TARGET TIME")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(theme.textSecondary)

                                Text("OPTIONAL")
                                    .font(.system(size: 9, weight: .regular))
                                    .tracking(1.5)
                                    .foregroundStyle(theme.textTertiary)
                            }

                            Spacer()

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    hasTime.toggle()
                                    if !hasTime {
                                        isTimePickerExpanded = false
                                        var comps = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
                                        comps.hour = 23
                                        comps.minute = 59
                                        comps.second = 59
                                        targetDate = Calendar.current.date(from: comps) ?? targetDate
                                    } else {
                                        isTimePickerExpanded = true
                                        isDatePickerExpanded = false
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: hasTime ? "clock.fill" : "clock")
                                        .font(.system(size: 11))

                                    Text(hasTime ? "REMOVE" : "ADD TIME")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1.5)
                                }
                                .foregroundStyle(theme.accent)
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
                            Text("TASKS")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(theme.textSecondary)

                            Text("OPTIONAL")
                                .font(.system(size: 9, weight: .regular))
                                .tracking(1.5)
                                .foregroundStyle(theme.textTertiary)
                        }

                        VStack(spacing: 8) {
                            // Existing Tasks
                            ForEach(todos) { task in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(theme.accent)
                                        .frame(width: 6, height: 6)

                                    Text(task.text)
                                        .font(.system(size: 15))
                                        .foregroundStyle(theme.textPrimary)

                                    Spacer()

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
                            }

                            // Add Task Row
                            HStack(spacing: 12) {
                                Circle()
                                    .stroke(theme.textTertiary, lineWidth: 1)
                                    .frame(width: 6, height: 6)

                                TextField("Add a task…", text: $todoInput)
                                    .font(.system(size: 15))
                                    .foregroundStyle(theme.textPrimary)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        addTodo()
                                    }

                                if !todoInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Button {
                                        addTodo()
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(theme.accent)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surfaceLight.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.border.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }

                    // 5. BEGIN MISSION BUTTON
                    Button {
                        handleSubmit()
                    } label: {
                        Text("BEGIN MISSION")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(isReady ? theme.background : theme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isReady ? theme.accent : theme.surfaceLight)
                            )
                    }
                    .disabled(!isReady)
                    .padding(.top, 8)
                    .padding(.bottom, 60)
                }
                .padding(.horizontal, 24)
            }
            .background(theme.background.ignoresSafeArea())
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func addTodo() {
        let text = todoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        HapticsManager.shared.impact(.light)
        todos.append(TodoTask(text: text))
        todoInput = ""
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

        HapticsManager.shared.impact(.medium)
        AudioManager.shared.play(.missionStart)
        missionStore.createMission(
            title: trimmedTitle,
            targetDate: targetDate,
            note: nil,
            todos: todos
        )
        dismiss()
    }
}
