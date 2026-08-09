import { createContext, useContext } from 'react';
import { PomodoroState } from '../hooks/usePomodoro';

// Default no-op state for context initialization
const defaultState: PomodoroState = {
  phase: 'focus',
  timeRemaining: 25 * 60,
  totalTime: 25 * 60,
  isRunning: false,
  progress: 0,
  currentSession: 1,
  totalSessions: 4,
  isStarted: false,
  start: () => {},
  pause: () => {},
  reset: () => {},
};

export const PomodoroContext = createContext<PomodoroState>(defaultState);

export function usePomodoroContext(): PomodoroState {
  return useContext(PomodoroContext);
}
