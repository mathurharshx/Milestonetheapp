import SwiftUI

public struct MissionTodoListView: View {
    public let todos: [TodoTask]
    public let onToggle: (String) -> Void
    public let onDelete: (String) -> Void
    public let onMove: (IndexSet, Int) -> Void
    public let onAddTask: (String) -> Void
    public let onFocusTask: ((String, String) -> Void)?

    @State private var newTaskText: String = ""
    @State private var isReordering: Bool = false
    @AppStorage("milestone:isSpotlightActive") private var isSpotlight: Bool = false
    @State private var isConqueredExpanded: Bool = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.theme) private var theme

    @State private var hasAppeared: Bool = false

    public init(
        todos: [TodoTask],
        onToggle: @escaping (String) -> Void,
        onDelete: @escaping (String) -> Void,
        onMove: @escaping (IndexSet, Int) -> Void,
        onAddTask: @escaping (String) -> Void,
        onFocusTask: ((String, String) -> Void)? = nil
    ) {
        self.todos = todos
        self.onToggle = onToggle
        self.onDelete = onDelete
        self.onMove = onMove
        self.onAddTask = onAddTask
        self.onFocusTask = onFocusTask
    }

    private var activeTasks: [TodoTask] {
        todos.filter { !$0.done }
    }

    private var conqueredTasks: [TodoTask] {
        todos.filter(\.done)
    }

    private var doneCount: Int {
        conqueredTasks.count
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Section Header & Mode Controls ──
            HStack(spacing: 8) {
                Text("TASKS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                // Spotlight Mode Toggle
                if !todos.isEmpty {
                    Button {
                        HapticsManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isSpotlight.toggle()
                            if isSpotlight {
                                isReordering = false
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isSpotlight ? "scope" : "scope")
                                .font(.system(size: 10, weight: .bold))
                            Text("SPOTLIGHT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                        }
                        .foregroundStyle(isSpotlight ? theme.accent : theme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isSpotlight ? theme.accentDim : Color.clear)
                                .overlay(
                                    Capsule().stroke(isSpotlight ? theme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Reorder Mode Toggle (Normal mode with multiple active tasks)
                if !isSpotlight && activeTasks.count > 1 {
                    Button {
                        HapticsManager.shared.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isReordering.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isReordering ? "checkmark" : "arrow.up.arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text(isReordering ? "DONE" : "REORDER")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                        }
                        .foregroundStyle(isReordering ? theme.accent : theme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isReordering ? theme.accentDim : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Text("\(doneCount)/\(todos.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.bottom, 10)

            // ── Main Content Area ──
            if isSpotlight {
                // ── SPOTLIGHT MODE (ADHD Hyperfocus: isolates the single next step) ──
                spotlightView
            } else {
                // ── NORMAL LIST MODE ──
                normalListView
            }

            // ── Inline Add Task Row ──
            HStack(spacing: 12) {
                Circle()
                    .stroke(theme.textTertiary, lineWidth: 1)
                    .frame(width: 6, height: 6)
                    .padding(.leading, 7)

                TextField("Add a task…", text: $newTaskText)
                    .font(.system(size: 15))
                    .foregroundStyle(theme.textPrimary)
                    .focused($isInputFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        submitNewTask()
                    }

                if !newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        submitNewTask()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .padding(.vertical, 12)

            Divider()
                .overlay(isInputFocused ? theme.accent : theme.border)

            // ── DOPAMINE LEDGER (Collapsible Conquered Stack) ──
            if !conqueredTasks.isEmpty {
                conqueredStackView
            }
        }
        .padding(.top, 24)
        .onAppear {
            if !hasAppeared {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                    hasAppeared = true
                }
            }
        }
    }

    // ── Spotlight Mode View ──
    @ViewBuilder
    private var spotlightView: some View {
        if let currentTask = activeTasks.first {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 6, height: 6)
                        Text("STEP 1 OF \(activeTasks.count)")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.8)
                            .foregroundStyle(theme.accent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(theme.accentDim))

                    Spacer()

                    // Skip / Defer Button (cycles task to end to unblock executive dysfunction)
                    if activeTasks.count > 1 {
                        Button {
                            HapticsManager.shared.impact(.light)
                            if let taskIndex = todos.firstIndex(where: { $0.id == currentTask.id }) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    onMove(IndexSet(integer: taskIndex), todos.count)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("DEFER")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1)
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundStyle(theme.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(theme.surfaceLight))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(currentTask.text)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)

                HStack(spacing: 10) {
                    if let onFocus = onFocusTask {
                        Button {
                            HapticsManager.shared.impact(.medium)
                            onFocus(currentTask.id, currentTask.text)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .font(.system(size: 12, weight: .bold))
                                Text("FOCUS")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.5)
                            }
                            .foregroundStyle(theme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.accentDim)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(theme.accent.opacity(0.35), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        HapticsManager.shared.notification(.success)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            onToggle(currentTask.id)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .heavy))
                            Text("CONQUER")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(1.5)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.accent)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceLight.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.vertical, 8)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
        } else if todos.isEmpty {
            Text("No tasks added yet. Add your key milestone steps below.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(theme.textTertiary)
                .padding(.vertical, 12)
        } else {
            // All tasks conquered celebration card
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(theme.accent)

                Text("ALL TASKS CONQUERED")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(theme.textPrimary)

                Text("Every milestone action step has been completed.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceLight.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.accent.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.vertical, 8)
        }
    }

    // ── Normal List Mode View ──
    @ViewBuilder
    private var normalListView: some View {
        if activeTasks.isEmpty && conqueredTasks.isEmpty {
            Text("No tasks added yet. Add your key milestone steps below.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(theme.textTertiary)
                .padding(.vertical, 12)
        } else if activeTasks.isEmpty && !conqueredTasks.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accent)
                Text("All active tasks completed. Check Conquered below.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.vertical, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(activeTasks.enumerated()), id: \.element.id) { index, task in
                    VStack(spacing: 0) {
                        SwipeableTaskRow(
                            task: task,
                            index: index,
                            totalCount: activeTasks.count,
                            isReordering: isReordering,
                            onToggle: {
                                onToggle(task.id)
                            },
                            onDelete: {
                                onDelete(task.id)
                            },
                            onMoveUp: {
                                moveActiveTask(from: index, direction: -1)
                            },
                            onMoveDown: {
                                moveActiveTask(from: index, direction: 1)
                            },
                            onFocusTask: onFocusTask != nil ? {
                                onFocusTask?(task.id, task.text)
                            } : nil
                        )

                        Divider().overlay(theme.divider)
                    }
                    .scrollTransition(.animated.threshold(.visible(0.15))) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1.0 : 0.7)
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.96)
                            .offset(y: phase.isIdentity ? 0 : (phase.value < 0 ? -8 : 8))
                    }
                    .offset(y: hasAppeared ? 0 : 22)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.76)
                        .delay(min(Double(index) * 0.05, 0.45)),
                        value: hasAppeared
                    )
                }
            }
        }
    }

    // ── Conquered Stack View (Dopamine Ledger) ──
    @ViewBuilder
    private var conqueredStackView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                HapticsManager.shared.impact(.light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isConqueredExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isConqueredExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(theme.textTertiary)

                    Text("CONQUERED")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(theme.textTertiary)

                    Text("(\(conqueredTasks.count))")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(theme.accent.opacity(0.85))

                    Spacer()

                    Text(isConqueredExpanded ? "HIDE" : "SHOW")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(theme.textMuted)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isConqueredExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(conqueredTasks.enumerated()), id: \.element.id) { index, task in
                        VStack(spacing: 0) {
                            SwipeableTaskRow(
                                task: task,
                                index: index,
                                totalCount: conqueredTasks.count,
                                isReordering: false,
                                onToggle: {
                                    onToggle(task.id)
                                },
                                onDelete: {
                                    onDelete(task.id)
                                },
                                onMoveUp: {},
                                onMoveDown: {},
                                onFocusTask: nil
                            )

                            Divider().overlay(theme.divider)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .padding(.top, 6)
    }

    private func moveActiveTask(from activeIndex: Int, direction: Int) {
        guard activeIndex >= 0 && activeIndex < activeTasks.count else { return }
        let targetActiveIndex = activeIndex + direction
        guard targetActiveIndex >= 0 && targetActiveIndex < activeTasks.count else { return }

        let currentId = activeTasks[activeIndex].id
        let targetId = activeTasks[targetActiveIndex].id

        guard let fromIndex = todos.firstIndex(where: { $0.id == currentId }),
              let toIndex = todos.firstIndex(where: { $0.id == targetId }) else { return }

        let finalOffset = direction > 0 ? toIndex + 1 : toIndex
        onMove(IndexSet(integer: fromIndex), finalOffset)
    }

    private func submitNewTask() {
        let text = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        HapticsManager.shared.impact(.light)
        onAddTask(text)
        newTaskText = ""
    }
}

// ── Swipeable Task Row Component ──
private struct SwipeableTaskRow: View {
    let task: TodoTask
    let index: Int
    let totalCount: Int
    let isReordering: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onFocusTask: (() -> Void)?

    @Environment(\.theme) private var theme
    @State private var dragOffset: CGFloat = 0
    @State private var isSwiping: Bool = false

    var body: some View {
        ZStack {
            // Background Action Reveal (Green on right swipe, Red on left swipe)
            HStack {
                if dragOffset > 0 {
                    // Complete Action
                    HStack(spacing: 6) {
                        Image(systemName: task.done ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(task.done ? "Undone" : "Done")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color(uiColor: .systemGreen))
                    .padding(.leading, 16)

                    Spacer()
                } else if dragOffset < 0 {
                    Spacer()

                    // Delete Action
                    HStack(spacing: 6) {
                        Text("Delete")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "trash.fill")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(theme.danger)
                    .padding(.trailing, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                dragOffset > 0
                    ? Color(uiColor: .systemGreen).opacity(0.12)
                    : (dragOffset < 0 ? theme.danger.opacity(0.12) : Color.clear)
            )

            // Foreground Content
            HStack(spacing: 12) {
                if isReordering {
                    // Priority Reordering Arrows
                    HStack(spacing: 8) {
                        Button {
                            HapticsManager.shared.impact(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                onMoveUp()
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(index > 0 ? theme.accent : theme.textMuted)
                                .frame(width: 24, height: 24)
                        }
                        .disabled(index == 0)

                        Button {
                            HapticsManager.shared.impact(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                onMoveDown()
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(index < totalCount - 1 ? theme.accent : theme.textMuted)
                                .frame(width: 24, height: 24)
                        }
                        .disabled(index == totalCount - 1)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // Checkbox
                Button {
                    HapticsManager.shared.selection()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        onToggle()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(task.done ? theme.accent : theme.textTertiary, lineWidth: 1.5)
                            .frame(width: 20, height: 20)

                        if task.done {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(theme.accentDim)
                                .frame(width: 20, height: 20)

                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .frame(width: 38, height: 38)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Task Title with Progressive Strikethrough Sweep Animation
                ZStack(alignment: .leading) {
                    Text(task.text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(task.done ? theme.textTertiary : theme.textPrimary)
                        .opacity(task.done ? 0.45 : 1.0)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .animation(.easeInOut(duration: 0.28), value: task.done)

                    GeometryReader { textGeo in
                        Rectangle()
                            .fill(theme.textTertiary)
                            .frame(height: 1.2)
                            .scaleEffect(x: task.done ? 1.0 : 0.0, y: 1.0, anchor: .leading)
                            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: task.done)
                            .position(x: textGeo.size.width / 2, y: textGeo.size.height / 2)
                    }
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticsManager.shared.selection()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        onToggle()
                    }
                }

                Spacer()

                if isReordering {
                    // Priority Badge
                    Text("#\(index + 1)")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(theme.accentDim)
                        )
                } else if !task.done, let onFocus = onFocusTask {
                    // Focus on Task in Pomodoro Shortcut
                    Button {
                        HapticsManager.shared.impact(.light)
                        onFocus()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10, weight: .bold))
                            Text("FOCUS")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                        }
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(theme.accentDim)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
            .background(theme.background)
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onChanged { gesture in
                        guard !isReordering else { return }
                        let translation = gesture.translation.width
                        // Apply friction beyond threshold
                        if translation > 0 {
                            dragOffset = min(translation * 0.7, 100)
                        } else {
                            dragOffset = max(translation * 0.7, -100)
                        }
                    }
                    .onEnded { gesture in
                        guard !isReordering else { return }
                        let translation = gesture.translation.width
                        if translation > 60 {
                            // Swiped right -> Toggle Complete
                            HapticsManager.shared.notification(.success)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                onToggle()
                                dragOffset = 0
                            }
                        } else if translation < -60 {
                            // Swiped left -> Delete Task
                            HapticsManager.shared.impact(.heavy)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                onDelete()
                                dragOffset = 0
                            }
                        } else {
                            // Spring back
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
    }
}
