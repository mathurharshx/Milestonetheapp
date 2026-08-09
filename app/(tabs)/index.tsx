import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useMissionContext } from '../../store/missionStore';
import { useCountdown } from '../../hooks/useCountdown';
import { getRandomQuote, Quote } from '../../utils/quotes';
import CreateMissionForm from '../../components/mission/CreateMissionForm';
import CountdownTimer from '../../components/mission/CountdownTimer';
import DotVisualization from '../../components/mission/DotVisualization';
// ProgressStats removed — visual clutter
import MissionTodoList from '../../components/mission/MissionTodoList';
import QuoteModal from '../../components/shared/QuoteModal';
import { Spacing, FontSize, BorderRadius } from '../../utils/theme';
import { useTheme } from '../../store/themeContext';
import { triggerHaptic } from '../../utils/haptics';

export default function HomeScreen() {
  const { colors } = useTheme();
  const { state, createMission, completeMission, archiveMission, toggleTodo, addTodo } = useMissionContext();
  const [showQuote, setShowQuote] = useState(false);
  const [currentQuote, setCurrentQuote] = useState<Quote | null>(null);

  const handleCompleteMission = useCallback(() => {
    Alert.alert(
      'Complete Mission',
      'Mark this mission as complete?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Complete',
          onPress: () => {
            triggerHaptic();
            completeMission();
            setCurrentQuote(getRandomQuote());
            setShowQuote(true);
          },
        },
      ]
    );
  }, [completeMission]);

  const handleQuoteContinue = useCallback(async () => {
    triggerHaptic();
    setShowQuote(false);
    await archiveMission();
  }, [archiveMission]);

  if (state.isLoading) {
    return (
      <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="small" color={colors.accent} />
        </View>
      </SafeAreaView>
    );
  }

  // No active mission — show create form
  if (!state.activeMission) {
    return (
      <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
        <CreateMissionForm onSubmit={(title, targetDate, note, todos) => {
          triggerHaptic();
          createMission(title, targetDate, note, todos);
        }} />
      </SafeAreaView>
    );
  }

  // Active mission
  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Brand */}
      <View style={styles.topBar}>
        <Text style={[styles.brand, { color: colors.accent }]}>MILESTONE</Text>
      </View>

      <MissionView
          mission={state.activeMission}
          onComplete={handleCompleteMission}
          onToggleTodo={toggleTodo}
          onAddTask={addTodo}
        />

      <QuoteModal
        visible={showQuote}
        quote={currentQuote}
        onContinue={handleQuoteContinue}
      />
    </SafeAreaView>
  );
}

function MissionView({
  mission,
  onComplete,
  onToggleTodo,
  onAddTask,
}: {
  mission: NonNullable<ReturnType<typeof useMissionContext>['state']['activeMission']>;
  onComplete: () => void;
  onToggleTodo: (todoId: string) => Promise<void>;
  onAddTask: (text: string) => Promise<void>;
}) {
  const { colors } = useTheme();
  const countdown = useCountdown(mission.createdAt, mission.targetDate);

  return (
    <ScrollView
      style={styles.scrollView}
      contentContainerStyle={styles.scrollContent}
      showsVerticalScrollIndicator={false}
    >
      {/* Mission title */}
      <View style={styles.missionHeader}>
        <Text style={[styles.missionTitle, { color: colors.textPrimary }]}>{mission.title}</Text>
        {mission.note ? (
          <Text style={[styles.missionNote, { color: colors.textTertiary }]}>{mission.note}</Text>
        ) : null}
      </View>

      {/* Countdown */}
      <CountdownTimer countdown={countdown} />

      {/* Dot visualization */}
      <View style={styles.vizContainer}>
        <DotVisualization
          totalDays={countdown.totalDays}
          daysElapsed={countdown.daysElapsed}
          totalHours={countdown.totalHours}
          hoursElapsed={countdown.hoursElapsed}
          isUnder24h={countdown.isUnder24h}
        />
      </View>

      {/* To-do list */}
      <MissionTodoList todos={mission.todos} onToggle={onToggleTodo} onAddTask={onAddTask} />

      {/* Complete button */}
      <TouchableOpacity
        style={[styles.completeButton, { borderColor: colors.accent }]}
        onPress={onComplete}
        activeOpacity={0.7}
      >
        <Text style={[styles.completeButtonText, { color: colors.accent }]}>MARK COMPLETE</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  topBar: {
    paddingHorizontal: Spacing.xxl,
    paddingTop: Spacing.lg,
    paddingBottom: Spacing.lg,
  },
  brand: {
    fontSize: FontSize.caption,
    fontWeight: '800',
    letterSpacing: 4,
    marginLeft: 4,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: Spacing.xxl,
    paddingBottom: 96,
  },
  missionHeader: {
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  missionTitle: {
    fontSize: FontSize.xxl,
    fontWeight: '500',
    textAlign: 'center',
    letterSpacing: -0.5,
  },
  missionNote: {
    fontSize: FontSize.md,
    fontWeight: '400',
    textAlign: 'center',
    marginTop: Spacing.sm,
  },
  vizContainer: {
    marginVertical: Spacing.xl,
  },
  completeButton: {
    height: 52,
    borderWidth: 1,
    borderRadius: BorderRadius.sm,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: Spacing.xxxl,
  },
  completeButtonText: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    letterSpacing: 3,
  },
});
