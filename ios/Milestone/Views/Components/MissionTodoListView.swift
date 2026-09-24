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
    @State private var isSpotlight: Bool = false
    @State private var spotlightTaskId: String? = nil
    @State private var spotlightDragOffset: CGFloat = 0
    @State private var spotlightSlideDirection: Int = 1
    @State private var isCompletedExpanded: Bool = false
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

    private var completedTasks: [TodoTask] {
        todos.filter(\.done)
    }

    private var doneCount: Int {
        completedTasks.count
    }

    private var currentSpotlightTask: TodoTask? {
        if let spotlightTaskId, let task = activeTasks.first(where: { $0.id == spotlightTaskId }) {
            return task
        }
        return activeTasks.first
    }

    private var currentSpotlightIndex: Int {
        guard let current = currentSpotlightTask,
              let idx = activeTasks.firstIndex(where: { $0.id == current.id }) else {
            return 0
        }
        return idx
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Section Header & Mode Controls ──
            HStack(spacing: 8) {
                Text(isSpotlight ? "SPOTLIGHT" : "TASKS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(isSpotlight ? theme.accent : theme.textSecondary)

                Spacer()

                // Mode Toggle Button (Spotlight / All Tasks)
                if !todos.isEmpty {
                    Button {
                        HapticsManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isSpotlight.toggle()
                            if isSpotlight {
                                isReordering = false
                                if spotlightTaskId == nil {
                                    spotlightTaskId = activeTasks.first?.id
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: isSpotlight ? "list.bullet" : "scope")
                                .font(.system(size: 10, weight: .bold))
                            Text(isSpotlight ? "ALL TASKS" : "SPOTLIGHT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.2)
                        }
                        .foregroundStyle(isSpotlight ? theme.textPrimary : theme.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isSpotlight ? theme.surfaceLight.opacity(0.45) : Color.clear)
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
                                .fill(isReordering ? theme.accentDim.opacity(0.45) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Counter only in Normal mode
                if !isSpotlight {
                    Text("\(doneCount)/\(todos.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(theme.textTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                }
            }
            .padding(.bottom, 10)

            // ── Main Content Area ──
            if isSpotlight {
                // ── SPOTLIGHT MODE (Ultra-minimal: isolates the single next step) ──
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
                .overlay(isInputFocused ? theme.accent : theme.border.opacity(0.35))

            // ── Completed Tasks Drawer ──
            if !completedTasks.isEmpty {
                completedStackView
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

    // ── Translucent Spotlight Mode ──
    @ViewBuilder
    private var spotlightView: some View {
        if let currentTask = currentSpotlightTask {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Checkbox
                    Button {
                        HapticsManager.shared.notification(.success)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            onToggle(currentTask.id)
                            advanceSpotlightAfterToggle(completedId: currentTask.id)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(theme.accent, lineWidth: 1.5)
                                .frame(width: 20, height: 20)

                            Circle()
                                .fill(theme.accent)
                                .frame(width: 6, height: 6)
                        }
                        .frame(width: 38, height: 38)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Task Text
                    Text(currentTask.text)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .animation(.easeInOut(duration: 0.2), value: currentTask.id)

                    Spacer()

                    // Focus Timer shortcut
                    if let onFocus = onFocusTask {
                        Button {
                            HapticsManager.shared.impact(.light)
                            onFocus(currentTask.id, currentTask.text)
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

                    // Step Indicator with Chevrons
                    if activeTasks.count > 1 {
                        HStack(spacing: 4) {
                            Button {
                                HapticsManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    cycleSpotlightTask(direction: -1)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(theme.textTertiary)
                                    .frame(width: 20, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Previous step")

                            Text("\(currentSpotlightIndex + 1)/\(activeTasks.count)")
                                .font(.system(size: 11, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(theme.accent)

                            Button {
                                HapticsManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    cycleSpotlightTask(direction: 1)
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(theme.textTertiary)
                                    .frame(width: 20, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Next step")
                        }
                    }
                }
                .padding(.vertical, 12)
                .offset(x: spotlightDragOffset)
                // ── Tactile Slide / Swipe to cycle between tasks ──
                .highPriorityGesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { gesture in
                            guard activeTasks.count > 1 else { return }
                            let dx = gesture.translation.width
                            let dy = gesture.translation.height
                            guard abs(dx) > abs(dy) * 0.7 else { return }
                            withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.8)) {
                                spotlightDragOffset = dx * 0.45
                            }
                        }
                        .onEnded { gesture in
                            guard activeTasks.count > 1 else { return }
                            let dx = gesture.translation.width
                            if dx < -35 {
                                // Swiped left -> next task
                                HapticsManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                    cycleSpotlightTask(direction: 1)
                                    spotlightDragOffset = 0
                                }
                            } else if dx > 35 {
                                // Swiped right -> previous task
                                HapticsManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                    cycleSpotlightTask(direction: -1)
                                    spotlightDragOffset = 0
                                }
                            } else {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                    spotlightDragOffset = 0
                                }
                            }
                        }
                )

                Divider().overlay(theme.divider.opacity(0.35))
            }
            .transition(.opacity)
        } else if todos.isEmpty {
            Text("No tasks added yet. Add your key milestone steps below.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(theme.textTertiary)
                .padding(.vertical, 12)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accent)
                Text("All tasks completed.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.vertical, 12)
        }
    }

    // ── Normal List Mode View ──
    @ViewBuilder
    private var normalListView: some View {
        if activeTasks.isEmpty && completedTasks.isEmpty {
            Text("No tasks added yet. Add your key milestone steps below.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(theme.textTertiary)
                .padding(.vertical, 12)
        } else if activeTasks.isEmpty && !completedTasks.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accent)
                Text("All active tasks completed. Check Completed below.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.vertical, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(activeTasks.enumerated()), id: \.element.id) { index, task in
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
                        } : nil,
                        onSpotlight: {
                            spotlightTask(id: task.id)
                        }
                    )
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

    // ── Completed Tasks Drawer ──
    @ViewBuilder
    private var completedStackView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                HapticsManager.shared.impact(.light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isCompletedExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isCompletedExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(theme.textTertiary)

                    Text("COMPLETED")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(theme.textTertiary)

                    Text("(\(completedTasks.count))")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(theme.accent.opacity(0.85))

                    Spacer()

                    Text(isCompletedExpanded ? "HIDE" : "SHOW")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(theme.textMuted)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isCompletedExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(completedTasks.enumerated()), id: \.element.id) { index, task in
                        SwipeableTaskRow(
                            task: task,
                            index: index,
                            totalCount: completedTasks.count,
                            isReordering: false,
                            onToggle: {
                                onToggle(task.id)
                            },
                            onDelete: {
                                onDelete(task.id)
                            },
                            onMoveUp: {},
                            onMoveDown: {},
                            onFocusTask: nil,
                            onSpotlight: nil
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .padding(.top, 6)
    }

    private func spotlightTask(id: String) {
        HapticsManager.shared.impact(.medium)
        spotlightTaskId = id
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            isSpotlight = true
            isReordering = false
        }
    }

    private func cycleSpotlightTask(direction: Int) {
        guard !activeTasks.isEmpty else { return }
        spotlightSlideDirection = direction
        let newIndex = (currentSpotlightIndex + direction + activeTasks.count) % activeTasks.count
        spotlightTaskId = activeTasks[newIndex].id
    }

    private func advanceSpotlightAfterToggle(completedId: String) {
        let remaining = activeTasks.filter { $0.id != completedId }
        if let next = remaining.first {
            spotlightSlideDirection = 1
            spotlightTaskId = next.id
        } else {
            isSpotlight = false
            spotlightTaskId = nil
        }
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
    let onSpotlight: (() -> Void)?

    @Environment(\.theme) private var theme
    @State private var dragOffset: CGFloat = 0
    @State private var isHorizontalDrag: Bool = false

    // Raw drag distance needed to commit an action
    private let triggerThreshold: CGFloat = 65
    // Max visible travel before hard rubber-band
    private let dragCap: CGFloat = 88

    // Proportional reveal for the action hint labels (0→1 over first half of travel)
    private var actionProgress: CGFloat {
        min(abs(dragOffset) / (triggerThreshold * 0.6), 1.0)
    }

    // App-brand colours (consistent with the rest of the app)
    private var completionColor: Color { AppColors.personalEmerald }
    private var deleteColor: Color { theme.danger }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // ── Action Background ──
                // Always present, tinted by swipe direction with proportional opacity.
                // No sudden pop — colour fades in smoothly as the row slides away.
                Color.clear
                    .background(
                        dragOffset > 0
                            ? completionColor.opacity(0.13 * actionProgress)
                            : (dragOffset < 0 ? deleteColor.opacity(0.13 * actionProgress) : Color.clear)
                    )
                    .overlay(alignment: dragOffset >= 0 ? .leading : .trailing) {
                        if dragOffset > 0 {
                            // Right-swipe hint → Complete / Undo
                            HStack(spacing: 6) {
                                Image(systemName: task.done
                                      ? "arrow.uturn.backward.circle"
                                      : "checkmark.circle")
                                    .font(.system(size: 17, weight: .semibold))
                                Text(task.done ? "Undo" : "Done")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(0.3)
                            }
                            .foregroundStyle(completionColor)
                            .opacity(actionProgress)
                            .padding(.leading, 18)
                        } else if dragOffset < 0 {
                            // Left-swipe hint → Delete
                            HStack(spacing: 6) {
                                Text("Delete")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(0.3)
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(deleteColor)
                            .opacity(actionProgress)
                            .padding(.trailing, 18)
                        }
                    }

                // ── Foreground Row Content ──
                // Clear at rest → atmosphere bleeds through.
                // Solid theme.background only while dragging → cleanly masks the action zone.
                rowContent
                    .background(abs(dragOffset) > 0 ? theme.background : Color.clear)
                    .offset(x: dragOffset)
            }

            Divider()
                .overlay(theme.divider.opacity(0.35))
        }
        .contextMenu {
            if !task.done, let onSpotlight {
                Button {
                    HapticsManager.shared.impact(.medium)
                    onSpotlight()
                } label: {
                    Label("Spotlight This Task", systemImage: "scope")
                }
            }

            if !task.done, let onFocus = onFocusTask {
                Button {
                    HapticsManager.shared.impact(.light)
                    onFocus()
                } label: {
                    Label("Focus with Timer", systemImage: "timer")
                }
            }

            Button(role: .destructive) {
                HapticsManager.shared.impact(.heavy)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onDelete()
                }
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .onChanged { gesture in
                    guard !isReordering else { return }
                    let dx = gesture.translation.width
                    let dy = gesture.translation.height

                    // Axis-lock: lock to horizontal once intent is clear,
                    // then ignore vertical drift for the rest of this gesture.
                    if !isHorizontalDrag {
                        guard abs(dx) > abs(dy) * 1.1 else { return }
                        isHorizontalDrag = true
                    }

                    // Rubber-band: 0.72 friction up to cap, then compressed further
                    let sign: CGFloat = dx > 0 ? 1 : -1
                    let absDx = abs(dx)
                    let scaled: CGFloat
                    if absDx * 0.72 <= dragCap {
                        scaled = absDx * 0.72
                    } else {
                        let excess = absDx * 0.72 - dragCap
                        scaled = dragCap + excess * 0.18
                    }
                    dragOffset = sign * min(scaled, dragCap + 14)
                }
                .onEnded { gesture in
                    defer { isHorizontalDrag = false }

                    guard !isReordering, isHorizontalDrag else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                            dragOffset = 0
                        }
                        return
                    }

                    let dx = gesture.translation.width

                    if dx > triggerThreshold {
                        // ✅ Committed right swipe → Toggle complete / undo
                        HapticsManager.shared.notification(.success)
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.76)) {
                            dragOffset = 0
                        }
                        // Slight delay lets spring-back animate before model update
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                            onToggle()
                        }
                    } else if dx < -triggerThreshold {
                        // 🗑️ Committed left swipe → Delete
                        HapticsManager.shared.impact(.heavy)
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.76)) {
                            dragOffset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                            onDelete()
                        }
                    } else {
                        // Below threshold → spring back
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    // ── Main Row Content ──
    @ViewBuilder
    private var rowContent: some View {
        HStack(spacing: 12) {
            if isReordering {
                reorderArrows
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

            // Task text with progressive strikethrough sweep
            Text(task.text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(task.done ? theme.textTertiary : theme.textPrimary)
                .opacity(task.done ? 0.45 : 1.0)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .animation(.easeInOut(duration: 0.28), value: task.done)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(theme.textTertiary)
                        .frame(height: 1.2)
                        .scaleEffect(x: task.done ? 1.0 : 0.0, anchor: .leading)
                        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: task.done)
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
                Text("#\(index + 1)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(theme.accentDim))
            } else if !task.done, let onFocus = onFocusTask {
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
                    .background(Capsule().fill(theme.accentDim))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }

    // ── Reorder Priority Arrows ──
    @ViewBuilder
    private var reorderArrows: some View {
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
    }
}

