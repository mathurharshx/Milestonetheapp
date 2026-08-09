import DateTimePicker from "@react-native-community/datetimepicker";
import React, { useRef, useState } from "react";
import {
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { TodoTask } from "../../store/missionStore";
import { BorderRadius, FontSize, Spacing } from "../../utils/theme";
import { useTheme } from "../../store/themeContext";
import { triggerHaptic } from "../../utils/haptics";
import * as Haptics from "expo-haptics";

interface CreateMissionFormProps {
  onSubmit: (
    title: string,
    targetDate: Date,
    note?: string,
    todos?: TodoTask[],
  ) => void;
}

function formatDate(date: Date): string {
  return date.toLocaleDateString("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric",
  });
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
}

const tomorrow = () => {
  const d = new Date();
  d.setDate(d.getDate() + 1);
  d.setHours(23, 59, 59, 0);
  return d;
};

export default function CreateMissionForm({
  onSubmit,
}: CreateMissionFormProps) {
  const { colors, mode } = useTheme();
  const [title, setTitle] = useState("");
  const [targetDate, setTargetDate] = useState<Date>(tomorrow());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [hasTime, setHasTime] = useState(false);
  const [focusedField, setFocusedField] = useState<string | null>(null);
  const [todos, setTodos] = useState<TodoTask[]>([]);
  const [todoInput, setTodoInput] = useState("");
  const todoInputRef = useRef<TextInput>(null);

  const addTodo = () => {
    const text = todoInput.trim();
    if (!text) return;
    setTodos((prev) => [
      ...prev,
      { id: Date.now().toString(), text, done: false },
    ]);
    setTodoInput("");
    todoInputRef.current?.focus();
  };

  const removeTodo = (id: string) => {
    setTodos((prev) => prev.filter((t) => t.id !== id));
  };

  const handleSubmit = () => {
    if (!title.trim()) {
      Alert.alert("Missing Title", "Please enter a mission title.");
      return;
    }

    const now = new Date();
    
    if (targetDate.toDateString() === now.toDateString() && !hasTime) {
      triggerHaptic(Haptics.ImpactFeedbackStyle.Heavy);
      Alert.alert(
        "Time Required",
        "Since this mission is for today, please add a specific target time.",
      );
      return;
    }

    if (targetDate <= now) {
      triggerHaptic(Haptics.ImpactFeedbackStyle.Heavy);
      Alert.alert(
        "Invalid Time",
        "Your target time must be in the future.",
      );
      return;
    }

    onSubmit(
      title.trim(),
      targetDate,
      undefined,
      todos.length > 0 ? todos : undefined,
    );
    setTitle("");
    setTargetDate(tomorrow());
    setShowDatePicker(false);
    setShowTimePicker(false);
    setHasTime(false);
    setTodos([]);
    setTodoInput("");
  };

  const isReady = title.trim().length > 0;

  // Allow selecting today (for time-based missions under 24h)
  const minDate = new Date();
  minDate.setHours(0, 0, 0, 0);

  const toggleTime = () => {
    if (hasTime) {
      // Remove time — reset to end of day
      const d = new Date(targetDate);
      d.setHours(23, 59, 59, 0);
      setTargetDate(d);
      setHasTime(false);
      setShowTimePicker(false);
    } else {
      // Add time — default to noon
      const d = new Date(targetDate);
      d.setHours(12, 0, 0, 0);
      setTargetDate(d);
      setHasTime(true);
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      style={[styles.container, { backgroundColor: colors.background }]}
    >
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={[styles.brandLabel, { color: colors.accent }]}>MILESTONE</Text>
          <Text style={[styles.title, { color: colors.textPrimary }]}>New Mission</Text>
          <Text style={[styles.subtitle, { color: colors.textTertiary }]}>One goal at a time.</Text>
        </View>

        {/* Form */}
        <View style={styles.form}>
          {/* Title Input */}
          <View style={styles.fieldContainer}>
            <Text style={[styles.label, { color: colors.textSecondary }]}>TITLE</Text>
            <TextInput
              style={[
                styles.input,
                styles.titleInput,
                { borderBottomColor: colors.border, color: colors.textPrimary },
                focusedField === "title" && { borderBottomColor: colors.accent },
              ]}
              placeholder="Define your mission"
              placeholderTextColor={colors.textMuted}
              value={title}
              onChangeText={setTitle}
              onFocus={() => setFocusedField("title")}
              onBlur={() => setFocusedField(null)}
              maxLength={100}
              autoCapitalize="sentences"
            />
          </View>

          {/* Date Picker */}
          <View style={styles.fieldContainer}>
            <Text style={[styles.label, { color: colors.textSecondary }]}>TARGET DATE</Text>
            <TouchableOpacity
              style={[
                styles.dateButton,
                { borderBottomColor: colors.border },
                showDatePicker && { borderBottomColor: colors.accent },
              ]}
              onPress={() => {
                setShowDatePicker((v) => !v);
                setShowTimePicker(false);
              }}
              activeOpacity={0.7}
            >
              <Text style={[styles.dateButtonText, { color: colors.textPrimary }]}>
                {formatDate(targetDate)}
              </Text>
              <Text style={[styles.dateChevron, { color: colors.textTertiary }]}>
                {showDatePicker ? "▲" : "▼"}
              </Text>
            </TouchableOpacity>

            {showDatePicker && (
              <View style={[styles.pickerWrapper, { backgroundColor: colors.surface }]}>
                <DateTimePicker
                  value={targetDate}
                  mode="date"
                  display={Platform.OS === "ios" ? "spinner" : "default"}
                  minimumDate={minDate}
                  onChange={(_, selected) => {
                    if (selected) {
                      const d = new Date(selected);
                      if (hasTime) {
                        d.setHours(
                          targetDate.getHours(),
                          targetDate.getMinutes(),
                          0,
                          0,
                        );
                      } else {
                        d.setHours(23, 59, 59, 0);
                      }
                      setTargetDate(d);
                    }
                    if (Platform.OS === "android") setShowDatePicker(false);
                  }}
                  themeVariant={mode}
                  style={styles.picker}
                />
                {Platform.OS === "ios" && (
                  <TouchableOpacity
                    style={[styles.doneButton, { borderTopColor: colors.border }]}
                    onPress={() => setShowDatePicker(false)}
                    activeOpacity={0.7}
                  >
                    <Text style={[styles.doneButtonText, { color: colors.accent }]}>DONE</Text>
                  </TouchableOpacity>
                )}
              </View>
            )}
          </View>

          {/* Time Picker (optional) */}
          <View style={styles.fieldContainer}>
            <View style={styles.timeLabelRow}>
              <Text style={[styles.label, { color: colors.textSecondary }]}>
                TARGET TIME <Text style={[styles.labelOptional, { color: colors.textTertiary }]}>OPTIONAL</Text>
              </Text>
              <TouchableOpacity onPress={toggleTime} activeOpacity={0.7}>
                <Text style={[styles.timeToggle, { color: colors.accent }]}>
                  {hasTime ? "REMOVE" : "ADD"}
                </Text>
              </TouchableOpacity>
            </View>

            {hasTime && (
              <>
                <TouchableOpacity
                  style={[
                    styles.dateButton,
                    { borderBottomColor: colors.border },
                    showTimePicker && { borderBottomColor: colors.accent },
                  ]}
                  onPress={() => {
                    setShowTimePicker((v) => !v);
                    setShowDatePicker(false);
                  }}
                  activeOpacity={0.7}
                >
                  <Text style={[styles.dateButtonText, { color: colors.textPrimary }]}>
                    {formatTime(targetDate)}
                  </Text>
                  <Text style={[styles.dateChevron, { color: colors.textTertiary }]}>
                    {showTimePicker ? "▲" : "▼"}
                  </Text>
                </TouchableOpacity>

                {showTimePicker && (
                  <View style={[styles.pickerWrapper, { backgroundColor: colors.surface }]}>
                    <DateTimePicker
                      value={targetDate}
                      mode="time"
                      display={Platform.OS === "ios" ? "spinner" : "default"}
                      onChange={(_, selected) => {
                        if (selected) {
                          const d = new Date(targetDate);
                          d.setHours(
                            selected.getHours(),
                            selected.getMinutes(),
                            0,
                            0,
                          );
                          setTargetDate(d);
                        }
                        if (Platform.OS === "android") setShowTimePicker(false);
                      }}
                      themeVariant={mode}
                      style={styles.picker}
                    />
                    {Platform.OS === "ios" && (
                      <TouchableOpacity
                        style={[styles.doneButton, { borderTopColor: colors.border }]}
                        onPress={() => setShowTimePicker(false)}
                        activeOpacity={0.7}
                      >
                        <Text style={[styles.doneButtonText, { color: colors.accent }]}>DONE</Text>
                      </TouchableOpacity>
                    )}
                  </View>
                )}
              </>
            )}
          </View>

          {/* To-Do Tasks */}
          <View style={styles.fieldContainer}>
            <Text style={[styles.label, { color: colors.textSecondary }]}>
              TASKS <Text style={[styles.labelOptional, { color: colors.textTertiary }]}>OPTIONAL</Text>
            </Text>

            {/* Existing tasks */}
            {todos.map((task) => (
              <View key={task.id} style={[styles.todoRow, { borderBottomColor: colors.border }]}>
                <View style={[styles.todoBullet, { backgroundColor: colors.accent }]} />
                <Text style={[styles.todoText, { color: colors.textPrimary }]} numberOfLines={2}>
                  {task.text}
                </Text>
                <TouchableOpacity
                  onPress={() => removeTodo(task.id)}
                  hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                >
                  <Text style={[styles.todoRemove, { color: colors.textTertiary }]}>✕</Text>
                </TouchableOpacity>
              </View>
            ))}

            {/* Add task row */}
            <View style={[styles.todoInputRow, { borderBottomColor: colors.border }]}>
              <View style={[styles.todoBulletEmpty, { borderColor: colors.textTertiary }]} />
              <TextInput
                ref={todoInputRef}
                style={[styles.todoInput, { color: colors.textPrimary }]}
                placeholder="Add a task…"
                placeholderTextColor={colors.textMuted}
                value={todoInput}
                onChangeText={setTodoInput}
                onSubmitEditing={addTodo}
                returnKeyType="done"
                blurOnSubmit={false}
                maxLength={120}
                onFocus={() => setFocusedField("todo")}
                onBlur={() => setFocusedField(null)}
              />
              {todoInput.trim().length > 0 && (
                <TouchableOpacity
                  onPress={addTodo}
                  hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                >
                  <Text style={[styles.todoAdd, { color: colors.accent }]}>＋</Text>
                </TouchableOpacity>
              )}
            </View>
          </View>

          {/* Divider */}
          <View style={[styles.divider, { backgroundColor: colors.divider }]} />

          {/* Submit */}
          <TouchableOpacity
            style={[
              styles.button,
              { backgroundColor: colors.accent },
              !isReady && { backgroundColor: colors.surfaceLight },
            ]}
            onPress={handleSubmit}
            activeOpacity={0.7}
            disabled={!isReady}
          >
            <Text
              style={[
                styles.buttonText,
                { color: colors.background },
                !isReady && { color: colors.textTertiary },
              ]}
            >
              BEGIN MISSION
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: "center",
    paddingHorizontal: Spacing.xxl,
    paddingVertical: Spacing.xxxxl,
  },
  header: {
    marginBottom: Spacing.xxxl,
  },
  brandLabel: {
    fontSize: FontSize.caption,
    fontWeight: "800",
    letterSpacing: 4,
    marginBottom: Spacing.xxl,
    marginLeft: 4,
  },
  title: {
    fontSize: FontSize.hero,
    fontWeight: "500",
    letterSpacing: -1,
    lineHeight: 60,
  },
  subtitle: {
    fontSize: FontSize.lg,
    fontWeight: "500",
    marginTop: Spacing.sm,
  },
  form: {
    gap: Spacing.xl,
  },
  fieldContainer: {
    gap: Spacing.sm,
  },
  label: {
    fontSize: FontSize.caption,
    fontWeight: "600",
    letterSpacing: 2,
  },
  labelOptional: {
    fontWeight: "400",
  },
  timeLabelRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  timeToggle: {
    fontSize: FontSize.caption,
    fontWeight: "600",
    letterSpacing: 2,
  },
  input: {
    height: 52,
    backgroundColor: "transparent",
    borderBottomWidth: 1,
    fontSize: FontSize.lg,
    fontWeight: "400",
    paddingHorizontal: 0,
    paddingVertical: Spacing.md,
  },
  titleInput: {
    fontSize: FontSize.xl,
    fontWeight: "500",
  },
  dateButton: {
    height: 52,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    borderBottomWidth: 1,
    paddingVertical: Spacing.md,
  },
  dateButtonText: {
    fontSize: FontSize.lg,
    fontWeight: "400",
  },
  dateChevron: {
    fontSize: 10,
  },
  pickerWrapper: {
    borderRadius: BorderRadius.sm,
    overflow: "hidden",
    marginTop: Spacing.sm,
  },
  picker: {
    width: "100%",
  },
  doneButton: {
    alignItems: "center",
    paddingVertical: Spacing.md,
    borderTopWidth: 1,
  },
  doneButtonText: {
    fontSize: FontSize.sm,
    fontWeight: "700",
    letterSpacing: 2,
  },
  // To-do styles
  todoRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: Spacing.sm,
    borderBottomWidth: 1,
    gap: Spacing.md,
  },
  todoBullet: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  todoText: {
    flex: 1,
    fontSize: FontSize.md,
    fontWeight: "400",
  },
  todoRemove: {
    fontSize: 11,
  },
  todoInputRow: {
    flexDirection: "row",
    alignItems: "center",
    borderBottomWidth: 1,
    gap: Spacing.md,
    paddingVertical: Spacing.xs,
  },
  todoBulletEmpty: {
    width: 6,
    height: 6,
    borderRadius: 3,
    borderWidth: 1,
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
  divider: {
    height: 1,
    marginVertical: Spacing.sm,
  },
  button: {
    height: 56,
    borderRadius: BorderRadius.xl,
    justifyContent: "center",
    alignItems: "center",
  },
  buttonText: {
    fontSize: FontSize.sm,
    fontWeight: "700",
    letterSpacing: 3,
  },
});
