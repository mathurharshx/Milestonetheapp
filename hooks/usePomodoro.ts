import { useState, useEffect, useRef, useCallback } from 'react';
import { syncPomodoroToWidget } from '../utils/widgetBridge';

export type PomodoroPhase = 'focus' | 'shortBreak' | 'longBreak';

export interface PomodoroState {
  /** Current phase */
  phase: PomodoroPhase;
  /** Seconds left in current phase */
  timeRemaining: number;
  /** Total seconds for current phase */
  totalTime: number;
  /** Is the timer actively counting down */
  isRunning: boolean;
  /** 0..1 progress through current phase */
  progress: number;
  /** Which focus session we're on: 1, 2, 3, or 4 */
  currentSession: number;
  /** Total focus sessions per cycle */
  totalSessions: number;
  /** Has the cycle been started at least once */
  isStarted: boolean;

  // Actions
  start: () => void;
  pause: () => void;
  reset: () => void;
}

const FOCUS_DURATION = 25 * 60;        // 25 minutes
const SHORT_BREAK_DURATION = 5 * 60;   // 5 minutes
const LONG_BREAK_DURATION = 20 * 60;   // 20 minutes
const SESSIONS_PER_CYCLE = 4;

function getDuration(phase: PomodoroPhase): number {
  switch (phase) {
    case 'focus': return FOCUS_DURATION;
    case 'shortBreak': return SHORT_BREAK_DURATION;
    case 'longBreak': return LONG_BREAK_DURATION;
  }
}

/**
 * Determines the next phase in the Pomodoro cycle.
 * Flow: focus → shortBreak → focus → shortBreak → focus → shortBreak → focus → longBreak → repeat
 */
function getNextPhase(currentPhase: PomodoroPhase, currentSession: number): {
  phase: PomodoroPhase;
  session: number;
} {
  if (currentPhase === 'focus') {
    // After the 4th focus session, take a long break
    if (currentSession >= SESSIONS_PER_CYCLE) {
      return { phase: 'longBreak', session: currentSession };
    }
    // Otherwise, short break
    return { phase: 'shortBreak', session: currentSession };
  }

  if (currentPhase === 'shortBreak') {
    // After short break, start next focus session
    return { phase: 'focus', session: currentSession + 1 };
  }

  // After long break, restart the cycle
  return { phase: 'focus', session: 1 };
}

export function usePomodoro(): PomodoroState {
  const [phase, setPhase] = useState<PomodoroPhase>('focus');
  const [currentSession, setCurrentSession] = useState(1);
  const [timeRemaining, setTimeRemaining] = useState(FOCUS_DURATION);
  const [isRunning, setIsRunning] = useState(false);
  const [isStarted, setIsStarted] = useState(false);

  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const endTimeRef = useRef<number | null>(null);

  const totalTime = getDuration(phase);

  const clearTimer = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    endTimeRef.current = null;
  }, []);

  // Auto-advance to the next phase
  const advanceToNextPhase = useCallback(() => {
    const next = getNextPhase(phase, currentSession);
    setPhase(next.phase);
    setCurrentSession(next.session);
    const duration = getDuration(next.phase);
    setTimeRemaining(duration);
    // Auto-start the next phase
    endTimeRef.current = Date.now() + duration * 1000;
    setIsRunning(true);
  }, [phase, currentSession]);

  const start = useCallback(() => {
    if (timeRemaining <= 0) return;
    setIsStarted(true);
    setIsRunning(true);
    endTimeRef.current = Date.now() + timeRemaining * 1000;
  }, [timeRemaining]);

  const pause = useCallback(() => {
    setIsRunning(false);
    if (endTimeRef.current) {
      const remaining = Math.max(0, Math.round((endTimeRef.current - Date.now()) / 1000));
      setTimeRemaining(remaining);
    }
    clearTimer();
  }, [clearTimer]);

  const reset = useCallback(() => {
    setIsRunning(false);
    setIsStarted(false);
    clearTimer();
    setPhase('focus');
    setCurrentSession(1);
    setTimeRemaining(FOCUS_DURATION);
  }, [clearTimer]);

  useEffect(() => {
    if (!isRunning) {
      clearTimer();
      return;
    }

    if (!endTimeRef.current) {
      endTimeRef.current = Date.now() + timeRemaining * 1000;
    }

    intervalRef.current = setInterval(() => {
      if (!endTimeRef.current) return;
      const remaining = Math.max(0, Math.round((endTimeRef.current - Date.now()) / 1000));
      setTimeRemaining(remaining);

      if (remaining <= 0) {
        clearTimer();
        // Auto-advance to next phase
        advanceToNextPhase();
      }
    }, 200);

    return () => clearTimer();
  }, [isRunning, advanceToNextPhase]);

  const progress = totalTime > 0 ? (totalTime - timeRemaining) / totalTime : 0;

  useEffect(() => {
    syncPomodoroToWidget({
      phase,
      timeRemaining,
      totalTime,
      isRunning,
      currentSession,
      totalSessions: SESSIONS_PER_CYCLE,
    });
  }, [phase, timeRemaining, totalTime, isRunning, currentSession]);

  return {
    phase,
    timeRemaining,
    totalTime,
    isRunning,
    progress,
    currentSession,
    totalSessions: SESSIONS_PER_CYCLE,
    isStarted,
    start,
    pause,
    reset,
  };
}
