import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { CountdownData } from '../../utils/dateCalculations';
import { Spacing, FontSize } from '../../utils/theme';
import { useTheme } from '../../store/themeContext';

interface ProgressStatsProps {
  countdown: CountdownData;
}

export default function ProgressStats({ countdown }: ProgressStatsProps) {
  const { colors } = useTheme();
  const { daysRemaining, totalDays, daysElapsed } = countdown;

  return (
    <View style={styles.container}>
      <StatItem label="REMAINING" value={daysRemaining} colors={colors} />
      <View style={[styles.divider, { backgroundColor: colors.border }]} />
      <StatItem label="ELAPSED" value={daysElapsed} colors={colors} />
      <View style={[styles.divider, { backgroundColor: colors.border }]} />
      <StatItem label="TOTAL" value={totalDays} colors={colors} />
    </View>
  );
}

function StatItem({ label, value, colors }: { label: string; value: number; colors: any }) {
  return (
    <View style={styles.item}>
      <Text style={[styles.value, { color: colors.textPrimary }]}>{value}</Text>
      <Text style={[styles.label, { color: colors.textTertiary }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.lg,
  },
  item: {
    flex: 1,
    alignItems: 'center',
  },
  value: {
    fontSize: FontSize.xl,
    fontWeight: '300',
    fontVariant: ['tabular-nums'],
  },
  label: {
    fontSize: 9,
    fontWeight: '600',
    letterSpacing: 2,
    marginTop: 6,
  },
  divider: {
    width: 1,
    height: 32,
  },
});
