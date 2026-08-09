import React, { createContext, useContext, useReducer, useEffect, useCallback } from 'react';
import {
  saveActiveMission,
  loadActiveMission,
  saveArchivedMissions,
  loadArchivedMissions,
} from '../utils/storage';
import { syncMissionToWidget } from '../utils/widgetBridge';

export interface TodoTask {
  id: string;
  text: string;
  done: boolean;
}

export interface Mission {
  id: string;
  title: string;
  note?: string;
  todos: TodoTask[];
  targetDate: Date;
  createdAt: Date;
  completedAt?: Date;
  isActive: boolean;
}

interface MissionState {
  activeMission: Mission | null;
  archivedMissions: Mission[];
  isLoading: boolean;
}

type MissionAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ACTIVE_MISSION'; payload: Mission | null }
  | { type: 'SET_ARCHIVED_MISSIONS'; payload: Mission[] }
  | { type: 'COMPLETE_MISSION' }
  | { type: 'ARCHIVE_MISSION' }
  | { type: 'TOGGLE_TODO'; payload: string }
  | { type: 'ADD_TODO'; payload: string }
  | { type: 'DELETE_ARCHIVED'; payload: string[] };

const initialState: MissionState = {
  activeMission: null,
  archivedMissions: [],
  isLoading: true,
};

function missionReducer(state: MissionState, action: MissionAction): MissionState {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'SET_ACTIVE_MISSION':
      return { ...state, activeMission: action.payload };
    case 'SET_ARCHIVED_MISSIONS':
      return { ...state, archivedMissions: action.payload };
    case 'COMPLETE_MISSION':
      if (!state.activeMission) return state;
      return {
        ...state,
        activeMission: {
          ...state.activeMission,
          completedAt: new Date(),
          isActive: false,
        },
      };
    case 'ARCHIVE_MISSION':
      if (!state.activeMission) return state;
      const completed = {
        ...state.activeMission,
        completedAt: state.activeMission.completedAt || new Date(),
        isActive: false,
      };
      return {
        ...state,
        activeMission: null,
        archivedMissions: [completed, ...state.archivedMissions],
      };
    case 'TOGGLE_TODO':
      if (!state.activeMission) return state;
      return {
        ...state,
        activeMission: {
          ...state.activeMission,
          todos: state.activeMission.todos.map((t) =>
            t.id === action.payload ? { ...t, done: !t.done } : t
          ),
        },
      };
    case 'ADD_TODO':
      if (!state.activeMission) return state;
      const newTodo: TodoTask = {
        id: Date.now().toString(),
        text: action.payload,
        done: false,
      };
      return {
        ...state,
        activeMission: {
          ...state.activeMission,
          todos: [...state.activeMission.todos, newTodo],
        },
      };
    case 'DELETE_ARCHIVED':
      return {
        ...state,
        archivedMissions: state.archivedMissions.filter(
          (m) => !action.payload.includes(m.id)
        ),
      };
    default:
      return state;
  }
}

interface MissionContextType {
  state: MissionState;
  createMission: (title: string, targetDate: Date, note?: string, todos?: TodoTask[]) => Promise<void>;
  completeMission: () => void;
  archiveMission: () => Promise<void>;
  toggleTodo: (todoId: string) => Promise<void>;
  addTodo: (text: string) => Promise<void>;
  deleteArchivedMissions: (ids: string[]) => Promise<void>;
  loadData: () => Promise<void>;
}

export const MissionContext = createContext<MissionContextType>({
  state: initialState,
  createMission: async () => {},
  completeMission: () => {},
  archiveMission: async () => {},
  toggleTodo: async () => {},
  addTodo: async () => {},
  deleteArchivedMissions: async () => {},
  loadData: async () => {},
});

export function useMissionContext() {
  return useContext(MissionContext);
}

export function useMissionReducer() {
  const [state, dispatch] = useReducer(missionReducer, initialState);

  const loadData = useCallback(async () => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const [active, archived] = await Promise.all([
        loadActiveMission(),
        loadArchivedMissions(),
      ]);
      dispatch({ type: 'SET_ACTIVE_MISSION', payload: active });
      dispatch({ type: 'SET_ARCHIVED_MISSIONS', payload: archived });
    } catch (err) {
      console.error('Failed to load data:', err);
    }
    dispatch({ type: 'SET_LOADING', payload: false });
  }, []);

  const createMission = useCallback(
    async (title: string, targetDate: Date, note?: string, todos?: TodoTask[]) => {
      const mission: Mission = {
        id: Date.now().toString(),
        title,
        note,
        todos: todos ?? [],
        targetDate,
        createdAt: new Date(),
        isActive: true,
      };
      dispatch({ type: 'SET_ACTIVE_MISSION', payload: mission });
      await saveActiveMission(mission);
    },
    []
  );

  const completeMission = useCallback(() => {
    dispatch({ type: 'COMPLETE_MISSION' });
  }, []);

  const archiveMission = useCallback(async () => {
    if (!state.activeMission) return;
    const completed = {
      ...state.activeMission,
      completedAt: state.activeMission.completedAt || new Date(),
      isActive: false,
    };
    const newArchived = [completed, ...state.archivedMissions];
    dispatch({ type: 'SET_ACTIVE_MISSION', payload: null });
    dispatch({ type: 'SET_ARCHIVED_MISSIONS', payload: newArchived });
    await saveActiveMission(null);
    await saveArchivedMissions(newArchived);
  }, [state.activeMission, state.archivedMissions]);

  const toggleTodo = useCallback(async (todoId: string) => {
    dispatch({ type: 'TOGGLE_TODO', payload: todoId });
    // Persist after state update via a small timeout to let reducer run first
    setTimeout(async () => {
      // We read from the ref-like closure; state here is stale, so we
      // re-read from storage and patch inline — simpler: just re-save
      // after the dispatch. We'll do it in the component via useEffect.
    }, 0);
  }, []);

  const addTodo = useCallback(async (text: string) => {
    dispatch({ type: 'ADD_TODO', payload: text });
  }, []);

  const deleteArchivedMissions = useCallback(async (ids: string[]) => {
    dispatch({ type: 'DELETE_ARCHIVED', payload: ids });
    const updated = state.archivedMissions.filter((m) => !ids.includes(m.id));
    await saveArchivedMissions(updated);
  }, [state.archivedMissions]);

  // Persist active mission whenever it changes
  useEffect(() => {
    if (!state.isLoading) {
      saveActiveMission(state.activeMission);
      syncMissionToWidget(state.activeMission);
    }
  }, [state.activeMission, state.isLoading]);

  return {
    state,
    createMission,
    completeMission,
    archiveMission,
    toggleTodo,
    addTodo,
    deleteArchivedMissions,
    loadData,
  };
}
