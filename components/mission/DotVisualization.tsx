import React, { useMemo } from 'react';
import { View, StyleSheet } from 'react-native';
import { Spacing } from '../../utils/theme';
import { useTheme } from '../../store/themeContext';

interface DotVisualizationProps {
  totalDays: number;
  daysElapsed: number;
  totalHours: number;
  hoursElapsed: number;
  isUnder24h: boolean;
}

export default function DotVisualization({
  totalDays,
  daysElapsed,
  totalHours,
  hoursElapsed,
  isUnder24h,
}: DotVisualizationProps) {
  const { colors } = useTheme();
  const totalUnits = isUnder24h ? totalHours : totalDays;
  const unitsElapsed = isUnder24h ? hoursElapsed : daysElapsed;

  const dots = useMemo(() => {
    if (totalUnits <= 0) return [];

    let displayDots = totalUnits;
    let sampleRate = 1;

    if (totalUnits > 365) {
      sampleRate = Math.ceil(totalUnits / 365);
      displayDots = Math.ceil(totalUnits / sampleRate);
    }
    if (displayDots > 500) {
      sampleRate = Math.ceil(totalUnits / 180);
      displayDots = Math.ceil(totalUnits / sampleRate);
    }

    const result: { elapsed: boolean }[] = [];

    for (let i = 0; i < displayDots; i++) {
      const originalUnit = i * sampleRate;
      const elapsed = originalUnit < unitsElapsed;
      result.push({ elapsed });
    }

    return result;
  }, [totalUnits, unitsElapsed]);

  if (totalUnits > 1095) return null;

  const dotSize = totalUnits <= 24 ? 8 : totalUnits <= 90 ? 6 : totalUnits <= 365 ? 4 : 3;
  const dotGap = totalUnits <= 24 ? 6 : totalUnits <= 90 ? 4 : 3;

  return (
    <View style={styles.dotGrid}>
      {dots.map((dot, index) => (
        <View
          key={index}
          style={[
            {
              width: dotSize,
              height: dotSize,
              borderRadius: dotSize / 2,
              marginRight: dotGap,
              marginBottom: dotGap,
              backgroundColor: dot.elapsed
                ? colors.dotElapsed
                : colors.dotFilled,
            },
            // Glow on the first remaining dot
            !dot.elapsed && index > 0 && dots[index - 1]?.elapsed
              ? {
                  shadowColor: colors.accent,
                  shadowRadius: 4,
                  shadowOpacity: 0.5,
                  elevation: 3,
                }
              : {},
          ]}
        />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  dotGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    paddingHorizontal: Spacing.md,
  },
});
