import React, { useEffect, useRef } from "react";
import {
  Animated,
  Dimensions,
  Easing,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { PomodoroPhase, PomodoroState } from "../../hooks/usePomodoro";
import { BorderRadius, FontSize, Spacing } from "../../utils/theme";
import { useTheme } from "../../store/themeContext";
import { triggerHaptic } from "../../utils/haptics";

interface PomodoroTimerProps {
  pomodoro: PomodoroState;
}

function getPhaseConfig(accent: string) {
  return {
    focus: {
      label: "FOCUS",
      color: accent,
      dimColor: accent + "14",
      message: "Stay locked in.",
    },
    shortBreak: {
      label: "SHORT BREAK",
      color: accent + "88",
      dimColor: accent + "0F",
      message: "Rest your eyes.",
    },
    longBreak: {
      label: "LONG BREAK",
      color: accent + "66",
      dimColor: accent + "0A",
      message: "You earned this.",
    },
  } as Record<PomodoroPhase, { label: string; color: string; dimColor: string; message: string }>;
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
}

const SCREEN_WIDTH = Dimensions.get("window").width;
const RING_SIZE = Math.min(SCREEN_WIDTH - 64, 300);
const SEGMENTS = 96;
const DOT_SIZE = 3.5;
const STROKE_WIDTH = DOT_SIZE;

function ProgressRing({
  progress,
  color,
  dotEmptyColor,
  children,
}: {
  progress: number;
  color: string;
  dotEmptyColor: string;
  children: React.ReactNode;
}) {
  const radius = (RING_SIZE - STROKE_WIDTH * 2) / 2;
  const centerX = RING_SIZE / 2;
  const centerY = RING_SIZE / 2;
  const filledCount = Math.round(progress * SEGMENTS);

  return (
    <View style={{ width: RING_SIZE, height: RING_SIZE }}>
      {Array.from({ length: SEGMENTS }).map((_, i) => {
        const angle = (i / SEGMENTS) * 2 * Math.PI - Math.PI / 2;
        const x = centerX + radius * Math.cos(angle);
        const y = centerY + radius * Math.sin(angle);
        const filled = i < filledCount;
        const isLead = filled && i === filledCount - 1;

        return (
          <View
            key={i}
            style={{
              position: "absolute",
              width: DOT_SIZE,
              height: DOT_SIZE,
              borderRadius: DOT_SIZE / 2,
              left: x - DOT_SIZE / 2,
              top: y - DOT_SIZE / 2,
              backgroundColor: filled ? color : dotEmptyColor,
              ...(isLead
                ? {
                    shadowColor: color,
                    shadowOpacity: 0.6,
                    shadowRadius: 6,
                    shadowOffset: { width: 0, height: 0 },
                    elevation: 6,
                    transform: [{ scale: 1.6 }],
                  }
                : {}),
            }}
          />
        );
      })}
      <View style={styles.ringCenter}>{children}</View>
    </View>
  );
}

export default function PomodoroTimer({ pomodoro }: PomodoroTimerProps) {
  const {
    phase,
    timeRemaining,
    isRunning,
    progress,
    currentSession,
    totalSessions,
    isStarted,
    start,
    pause,
    reset,
  } = pomodoro;

  const { colors } = useTheme();
  const PHASE_CONFIG = getPhaseConfig(colors.accent);
  const config = PHASE_CONFIG[phase];

  // Breathing pulse on the timer when running
  const pulseAnim = useRef(new Animated.Value(1)).current;
  // Phase badge fade-in on phase change
  const badgeFade = useRef(new Animated.Value(0)).current;
  const startFade = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.timing(startFade, {
      toValue: isStarted ? 1 : 0,
      duration: 300,
      useNativeDriver: true,
    }).start();
  }, [isStarted]);

  useEffect(() => {
    badgeFade.setValue(0);
    Animated.timing(badgeFade, {
      toValue: 1,
      duration: 400,
      easing: Easing.out(Easing.ease),
      useNativeDriver: true,
    }).start();
  }, [phase]);

  useEffect(() => {
    if (isRunning) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 0.65,
            duration: 1800,
            easing: Easing.inOut(Easing.sin),
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 1800,
            easing: Easing.inOut(Easing.sin),
            useNativeDriver: true,
          }),
        ]),
      ).start();
    } else {
      pulseAnim.stopAnimation();
      Animated.timing(pulseAnim, {
        toValue: 1,
        duration: 300,
        useNativeDriver: true,
      }).start();
    }
  }, [isRunning]);

  const nextLabel = getNextPhaseName(phase, currentSession);

  return (
    <View style={styles.container}>
      {/* Phase badge */}
      <Animated.View
        style={[
          styles.phaseBadge,
          { backgroundColor: config.dimColor, opacity: badgeFade },
        ]}
      >
        <Text style={[styles.phaseLabel, { color: config.color }]}>
          {config.label}
        </Text>
      </Animated.View>

      {/* Session dots */}
      <View style={styles.sessionRow}>
        {Array.from({ length: totalSessions }).map((_, i) => {
          const isActive = i < currentSession;
          const isCurrent = i === currentSession - 1 && phase === "focus";
          return (
            <View
              key={i}
              style={[
                styles.sessionDot,
                {
                  backgroundColor: isCurrent
                    ? config.color
                    : isActive
                      ? config.color + "44"
                      : colors.dotEmpty,
                  transform: [{ scale: isCurrent ? 1.3 : 1 }],
                },
              ]}
            />
          );
        })}
        <Text style={[styles.sessionCount, { color: colors.textTertiary }]}>
          {currentSession} / {totalSessions}
        </Text>
      </View>

      {/* Ring */}
      <View style={styles.ringWrapper}>
        <ProgressRing progress={progress} color={config.color} dotEmptyColor={colors.dotEmpty}>
          {/* Timer */}
          <Animated.Text style={[styles.timerText, { color: colors.textPrimary, opacity: pulseAnim }]}>
            {formatTime(timeRemaining)}
          </Animated.Text>

          {/* Status pill inside ring */}
          <View
            style={[styles.statusPill, { backgroundColor: config.dimColor }]}
          >
            <Text style={[styles.statusText, { color: config.color }]}>
              {isRunning ? "RUNNING" : isStarted ? "PAUSED" : "READY"}
            </Text>
          </View>

          {/* Message */}
          <Text style={[styles.phaseMessage, { color: colors.textTertiary }]}>{config.message}</Text>
        </ProgressRing>
      </View>

      {/* Controls */}
      <View style={styles.controls}>
        {!isRunning ? (
          <TouchableOpacity
            style={[styles.primaryBtn, { backgroundColor: config.color }]}
            onPress={() => {
              triggerHaptic();
              start();
            }}
            activeOpacity={0.75}
          >
            <Text style={[styles.primaryBtnText, { color: colors.background }]}>
              {isStarted ? "RESUME" : "START"}
            </Text>
          </TouchableOpacity>
        ) : (
          <TouchableOpacity
            style={[styles.outlineBtn, { borderColor: config.color + "44" }]}
            onPress={() => {
              triggerHaptic();
              pause();
            }}
            activeOpacity={0.75}
          >
            <Text style={[styles.outlineBtnText, { color: config.color }]}>
              PAUSE
            </Text>
          </TouchableOpacity>
        )}

        {isStarted && (
          <Animated.View style={{ opacity: startFade }}>
            <TouchableOpacity
              style={styles.ghostBtn}
              onPress={() => {
                triggerHaptic();
                reset();
              }}
              activeOpacity={0.6}
            >
              <Text style={[styles.ghostBtnText, { color: colors.textTertiary }]}>RESET</Text>
            </TouchableOpacity>
          </Animated.View>
        )}
      </View>

      {/* Next up */}
      <Animated.View style={[styles.nextRow, { opacity: startFade }]}>
        <Text style={[styles.nextLabel, { color: colors.textMuted }]}>NEXT</Text>
        <View style={[styles.nextDivider, { backgroundColor: colors.border }]} />
        <Text style={[styles.nextValue, { color: colors.textTertiary }]}>{nextLabel}</Text>
      </Animated.View>
    </View>
  );
}

function getNextPhaseName(phase: PomodoroPhase, session: number): string {
  if (phase === "focus") {
    return session >= 4 ? "Long Break  ·  20m" : "Short Break  ·  5m";
  }
  if (phase === "shortBreak") return `Focus ${session + 1} of 4  ·  25m`;
  return "Focus 1 of 4  ·  25m";
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: Spacing.xxl,
    paddingBottom: 96,
  },

  // Phase badge
  phaseBadge: {
    paddingVertical: 6,
    paddingHorizontal: 18,
    borderRadius: BorderRadius.full,
    marginBottom: Spacing.xl,
  },
  phaseLabel: {
    fontSize: 10,
    fontWeight: "700",
    letterSpacing: 3.5,
  },

  // Session row
  sessionRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginBottom: Spacing.xxl,
  },
  sessionDot: {
    width: 7,
    height: 7,
    borderRadius: 4,
  },
  sessionCount: {
    fontSize: 10,
    fontWeight: "500",
    letterSpacing: 1.5,
    marginLeft: 6,
  },

  // Ring
  ringWrapper: {
    marginBottom: Spacing.xxxl,
  },
  ringCenter: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: "center",
    alignItems: "center",
    gap: 6,
  },
  timerText: {
    fontSize: 58,
    fontWeight: "100",
    fontVariant: ["tabular-nums"],
    letterSpacing: 2,
    includeFontPadding: false,
  },
  statusPill: {
    paddingVertical: 3,
    paddingHorizontal: 10,
    borderRadius: BorderRadius.full,
  },
  statusText: {
    fontSize: 9,
    fontWeight: "700",
    letterSpacing: 3,
  },
  phaseMessage: {
    fontSize: FontSize.xs,
    fontWeight: "400",
    letterSpacing: 0.5,
    marginTop: 2,
  },

  // Controls
  controls: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.md,
  },
  primaryBtn: {
    height: 52,
    paddingHorizontal: 52,
    borderRadius: BorderRadius.xl,
    justifyContent: "center",
    alignItems: "center",
  },
  primaryBtnText: {
    fontSize: FontSize.xs,
    fontWeight: "700",
    letterSpacing: 3.5,
  },
  outlineBtn: {
    height: 52,
    paddingHorizontal: 52,
    borderRadius: BorderRadius.xl,
    justifyContent: "center",
    alignItems: "center",
    borderWidth: 1,
  },
  outlineBtnText: {
    fontSize: FontSize.xs,
    fontWeight: "700",
    letterSpacing: 3.5,
  },
  ghostBtn: {
    height: 52,
    paddingHorizontal: 20,
    justifyContent: "center",
    alignItems: "center",
  },
  ghostBtnText: {
    fontSize: FontSize.xs,
    fontWeight: "500",
    letterSpacing: 2,
  },

  // Next row
  nextRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    marginTop: Spacing.xxxl,
  },
  nextLabel: {
    fontSize: 9,
    fontWeight: "600",
    letterSpacing: 2.5,
  },
  nextDivider: {
    width: 16,
    height: 1,
  },
  nextValue: {
    fontSize: FontSize.xs,
    fontWeight: "400",
    letterSpacing: 0.5,
  },
});
