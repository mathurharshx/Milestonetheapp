import React, { useState } from 'react';
import { View, Text, TouchableOpacity, TextInput, StyleSheet } from 'react-native';
import { TodoTask } from '../../store/missionStore';
import { Spacing, FontSize, BorderRadius } from '../../utils/theme';
import { useTheme } from '../../store/themeContext';
import { triggerHaptic } from '../../utils/haptics';

interface MissionTodoListProps {
  todos: TodoTask[];
  onToggle: (id: string) => void;
  onAddTask: (text: string) => void;
}

export default function MissionTodoList({ todos, onToggle, onAddTask }: MissionTodoListProps) {
  const { colors } = useTheme();
  const [taskText, setTaskText] = useState('');
  const [isFocused, setIsFocused] = useState(false);

  const doneCount = todos.filter((t) => t.done).length;

  const handleAdd = () => {
    const text = taskText.trim();
    if (!text) return;
    triggerHaptic();
    onAddTask(text);
    setTaskText('');
  };

  return (
    <View style={[styles.container, { borderTopColor: colors.border }]}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={[styles.headerLabel, { color: colors.textSecondary }]}>TASKS</Text>
        <Text style={[styles.headerCount, { color: colors.textTertiary }]}>
          {doneCount}/{todos.length}
        </Text>
      </View>

      {/* Task rows */}
      {todos.map((task) => (
        <TouchableOpacity
          key={task.id}
          style={[styles.row, { borderBottomColor: colors.divider }]}
          onPress={() => onToggle(task.id)}
          activeOpacity={0.6}
        >
          {/* Checkbox */}
          <View style={[
            styles.checkbox,
            { borderColor: colors.textTertiary },
            task.done && { borderColor: colors.accent, backgroundColor: colors.accentDim },
          ]}>
            {task.done && <Text style={[styles.checkmark, { color: colors.accent }]}>✓</Text>}
          </View>

          {/* Text */}
          <Text style={[
            styles.taskText,
            { color: colors.textPrimary },
            task.done && { color: colors.textTertiary, textDecorationLine: 'line-through' },
          ]}>
            {task.text}
          </Text>
        </TouchableOpacity>
      ))}

      {/* Add Task Input */}
      <View style={[
        styles.todoInputRow,
        { borderBottomColor: colors.border },
        isFocused && { borderBottomColor: colors.accent }
      ]}>
        <View style={[styles.todoBulletEmpty, { borderColor: colors.textTertiary }]} />
        <TextInput
          style={[styles.todoInput, { color: colors.textPrimary }]}
          placeholder="Add a task…"
          placeholderTextColor={colors.textMuted}
          value={taskText}
          onChangeText={setTaskText}
          onSubmitEditing={handleAdd}
          returnKeyType="done"
          blurOnSubmit={false}
          maxLength={120}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
        />
        {taskText.trim().length > 0 && (
          <TouchableOpacity
            onPress={handleAdd}
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          >
            <Text style={[styles.todoAdd, { color: colors.accent }]}>＋</Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginTop: Spacing.xl,
    borderTopWidth: 1,
    paddingTop: Spacing.xl,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  headerLabel: {
    fontSize: FontSize.caption,
    fontWeight: '600',
    letterSpacing: 2,
  },
  headerCount: {
    fontSize: FontSize.caption,
    fontWeight: '600',
    letterSpacing: 1,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.md,
    gap: Spacing.md,
    borderBottomWidth: 1,
  },
  checkbox: {
    width: 20,
    height: 20,
    borderRadius: BorderRadius.sm,
    borderWidth: 1.5,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkmark: {
    fontSize: 11,
    fontWeight: '700',
    lineHeight: 14,
  },
  taskText: {
    flex: 1,
    fontSize: FontSize.md,
    fontWeight: '400',
    lineHeight: 22,
  },
  todoInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1,
    gap: Spacing.md,
    paddingVertical: Spacing.xs,
    marginTop: Spacing.sm,
  },
  todoBulletEmpty: {
    width: 6,
    height: 6,
    borderRadius: 3,
    borderWidth: 1,
    marginLeft: 7, // align checkbox visual alignment
  },
  todoInput: {
    flex: 1,
    height: 44,
    fontSize: FontSize.md,
    paddingVertical: Spacing.sm,
  },
  todoAdd: {
    fontSize: 20,
    lineHeight: 24,
  },
});

