import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { CountdownData } from '../../utils/dateCalculations';
import { Spacing, FontSize } from '../../utils/theme';
import { useTheme } from '../../store/themeContext';

interface CountdownTimerProps {
  countdown: CountdownData;
}

function pad(n: number): string {
  return n.toString().padStart(2, '0');
}

export default function CountdownTimer({ countdown }: CountdownTimerProps) {
  const { colors } = useTheme();
  const { days, hours, minutes, seconds } = countdown;

  return (
    <View style={styles.container}>
      {/* Days number */}
      <View style={styles.heroWrapper}>
        <Text style={[styles.heroNumber, { color: colors.textPrimary }]}>{days}</Text>
      </View>
      <Text style={[styles.heroLabel, { color: colors.textTertiary }]}>DAYS</Text>

      {/* HMS row — compact, directly under */}
      <View style={styles.hmsRow}>
        <TimeUnit value={hours} label="HR" colors={colors} />
        <Text style={[styles.colon, { color: colors.textMuted }]}>:</Text>
        <TimeUnit value={minutes} label="MIN" colors={colors} />
        <Text style={[styles.colon, { color: colors.textMuted }]}>:</Text>
        <TimeUnit value={seconds} label="SEC" colors={colors} />
      </View>
    </View>
  );
}

function TimeUnit({ value, label, colors }: { value: number; label: string; colors: any }) {
  return (
    <View style={styles.unit}>
      <Text style={[styles.unitValue, { color: colors.textTertiary }]}>{pad(value)}</Text>
      <Text style={[styles.unitLabel, { color: colors.textMuted }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    paddingVertical: Spacing.lg,
  },
  heroWrapper: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroNumber: {
    fontSize: FontSize.mega,
    fontWeight: '200',
    fontVariant: ['tabular-nums'],
    letterSpacing: -2,
    includeFontPadding: false,
    textAlignVertical: 'center',
    textAlign: 'center',
  },
  heroLabel: {
    fontSize: FontSize.caption,
    fontWeight: '600',
    letterSpacing: 6,
    marginTop: 2,
    textAlign: 'center',
  },
  hmsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: Spacing.sm,
  },
  unit: {
    alignItems: 'center',
    minWidth: 40,
  },
  unitValue: {
    fontSize: FontSize.lg,
    fontWeight: '400',
    fontVariant: ['tabular-nums'],
    letterSpacing: 1,
  },
  unitLabel: {
    fontSize: 8,
    fontWeight: '600',
    letterSpacing: 2,
    marginTop: 2,
  },
  colon: {
    fontSize: FontSize.lg,
    fontWeight: '300',
    marginHorizontal: 1,
    marginBottom: 12,
  },
});
