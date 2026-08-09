import SwiftUI

public struct MissionTodoListView: View {
    public let todos: [TodoTask]
    public let onToggle: (String) -> Void
    public let onAddTask: (String) -> Void

    @State private var newTaskText: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.theme) private var theme

    public init(
        todos: [TodoTask],
        onToggle: @escaping (String) -> Void,
        onAddTask: @escaping (String) -> Void
    ) {
        self.todos = todos
        self.onToggle = onToggle
        self.onAddTask = onAddTask
    }

    private var doneCount: Int {
        todos.filter(\.done).count
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("TASKS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                Text("\(doneCount)/\(todos.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.bottom, 12)

            // Task List
            ForEach(todos) { task in
                Button {
                    HapticsManager.shared.selection()
                    onToggle(task.id)
                } label: {
                    HStack(spacing: 12) {
                        // Checkbox
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(task.done ? theme.accent : theme.textTertiary, lineWidth: 1.5)
                                .frame(width: 20, height: 20)

                            if task.done {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.accentDim)
                                    .frame(width: 20, height: 20)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(theme.accent)
                            }
                        }

                        // Text
                        Text(task.text)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(task.done ? theme.textTertiary : theme.textPrimary)
                            .strikethrough(task.done, color: theme.textTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider()
                    .overlay(theme.divider)
            }

            // Inline Add Task Row
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
            .padding(.vertical, 10)

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
