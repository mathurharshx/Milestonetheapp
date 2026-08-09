/**
 * Widget Bridge Utility
 *
 * Syncs app state to shared UserDefaults so the iOS widget
 * can display current timer and mission data.
 *
 * This is the ONLY file that imports from the native module.
 * All other code should use these helper functions.
 */
import { Platform } from 'react-native';
// import { setSharedData, reloadWidget } from '../modules/widget-bridge';
import type { PomodoroPhase } from '../hooks/usePomodoro';
import type { Mission } from '../store/missionStore';

const WIDGET_DATA_KEY = 'milestoneWidgetData';

interface WidgetData {
  // Pomodoro
  pomodoroPhase: string;
  pomodoroTimeRemaining: number;
  pomodoroTotalTime: number;
  pomodoroIsRunning: boolean;
  pomodoroSession: number;
  pomodoroTotalSessions: number;
  // Mission
  missionTitle: string | null;
  missionTargetDate: number | null;
  missionCreatedAt: number | null;
  missionTodosTotal: number;
  missionTodosDone: number;
  // Meta
  lastUpdated: number;
}

// Cached state so we can merge partial updates
let cachedState: WidgetData = {
  pomodoroPhase: 'focus',
  pomodoroTimeRemaining: 25 * 60,
  pomodoroTotalTime: 25 * 60,
  pomodoroIsRunning: false,
  pomodoroSession: 1,
  pomodoroTotalSessions: 4,
  missionTitle: null,
  missionTargetDate: null,
  missionCreatedAt: null,
  missionTodosTotal: 0,
  missionTodosDone: 0,
  lastUpdated: Date.now() / 1000,
};

/** Flush the cached state to shared storage and reload widget */
function flush(): void {
  if (Platform.OS !== 'ios') return;
  cachedState.lastUpdated = Date.now() / 1000;
  // setSharedData(WIDGET_DATA_KEY, JSON.stringify(cachedState));
  // reloadWidget();
}

// ── Throttle: don't write more than once per second ──
let flushTimer: ReturnType<typeof setTimeout> | null = null;

function throttledFlush(): void {
  if (flushTimer) return;
  flushTimer = setTimeout(() => {
    flush();
    flushTimer = null;
  }, 1000);
}

/**
 * Update pomodoro state in the widget.
 * Call this from the pomodoro hook whenever state changes.
 */
export function syncPomodoroToWidget(params: {
  phase: PomodoroPhase;
  timeRemaining: number;
  totalTime: number;
  isRunning: boolean;
  currentSession: number;
  totalSessions: number;
}): void {
  if (Platform.OS !== 'ios') return;
  cachedState.pomodoroPhase = params.phase;
  cachedState.pomodoroTimeRemaining = params.timeRemaining;
  cachedState.pomodoroTotalTime = params.totalTime;
  cachedState.pomodoroIsRunning = params.isRunning;
  cachedState.pomodoroSession = params.currentSession;
  cachedState.pomodoroTotalSessions = params.totalSessions;
  throttledFlush();
}

/**
 * Update mission state in the widget.
 * Call this from the mission store whenever active mission changes.
 */
export function syncMissionToWidget(mission: Mission | null): void {
  if (Platform.OS !== 'ios') return;
  if (mission) {
    cachedState.missionTitle = mission.title;
    cachedState.missionTargetDate = mission.targetDate.getTime() / 1000;
    cachedState.missionCreatedAt = mission.createdAt.getTime() / 1000;
    cachedState.missionTodosTotal = mission.todos.length;
    cachedState.missionTodosDone = mission.todos.filter((t) => t.done).length;
  } else {
    cachedState.missionTitle = null;
    cachedState.missionTargetDate = null;
    cachedState.missionCreatedAt = null;
    cachedState.missionTodosTotal = 0;
    cachedState.missionTodosDone = 0;
  }
  flush(); // Mission changes are infrequent, flush immediately
}
