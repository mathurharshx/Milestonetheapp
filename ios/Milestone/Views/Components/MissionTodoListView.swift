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
    @FocusState private var isInputFocused: Bool
    @Environment(\.theme) private var theme

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

    private var doneCount: Int {
        todos.filter(\.done).count
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Section Header & Priority Controls ──
            HStack {
                Text("TASKS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                if todos.count > 1 {
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
                    .padding(.trailing, 8)
                }

                Text("\(doneCount)/\(todos.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.bottom, 10)

            // ── Task Items ──
            if todos.isEmpty {
                Text("No tasks added yet. Add your key milestone steps below.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.textTertiary)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todos.enumerated()), id: \.element.id) { index, task in
                        SwipeableTaskRow(
                            task: task,
                            index: index,
                            totalCount: todos.count,
                            isReordering: isReordering,
                            onToggle: {
                                onToggle(task.id)
                            },
                            onDelete: {
                                onDelete(task.id)
                            },
                            onMoveUp: {
                                guard index > 0 else { return }
                                onMove(IndexSet(integer: index), index - 1)
                            },
                            onMoveDown: {
                                guard index < todos.count - 1 else { return }
                                onMove(IndexSet(integer: index), index + 2)
                            },
                            onFocusTask: onFocusTask != nil ? {
                                onFocusTask?(task.id, task.text)
                            } : nil
                        )

                        Divider().overlay(theme.divider)
                    }
                }
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
        }
        .padding(.top, 24)
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
                }
                .buttonStyle(.plain)

                // Task Title
                Text(task.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(task.done ? theme.textTertiary : theme.textPrimary)
                    .strikethrough(task.done, color: theme.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticsManager.shared.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
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
