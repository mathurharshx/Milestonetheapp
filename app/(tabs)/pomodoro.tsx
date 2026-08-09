import React from 'react';
import { StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import PomodoroTimer from '../../components/pomodoro/PomodoroTimer';
import { usePomodoroContext } from '../../store/pomodoroContext';
import { useTheme } from '../../store/themeContext';

export default function PomodoroScreen() {
  const pomodoro = usePomodoroContext();
  const { colors } = useTheme();

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <PomodoroTimer pomodoro={pomodoro} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
