import AsyncStorage from '@react-native-async-storage/async-storage';
import { Mission } from '../store/missionStore';

const ACTIVE_MISSION_KEY = 'milestone:active-mission';
const ARCHIVED_MISSIONS_KEY = 'milestone:archived-missions';

function reviveDates(mission: any): Mission {
  return {
    ...mission,
    todos: mission.todos ?? [],
    createdAt: new Date(mission.createdAt),
    targetDate: new Date(mission.targetDate),
    completedAt: mission.completedAt ? new Date(mission.completedAt) : undefined,
  };
}

export async function saveActiveMission(mission: Mission | null): Promise<void> {
  if (mission === null) {
    await AsyncStorage.removeItem(ACTIVE_MISSION_KEY);
  } else {
    await AsyncStorage.setItem(ACTIVE_MISSION_KEY, JSON.stringify(mission));
  }
}

export async function loadActiveMission(): Promise<Mission | null> {
  try {
    const data = await AsyncStorage.getItem(ACTIVE_MISSION_KEY);
    if (!data) return null;
    return reviveDates(JSON.parse(data));
  } catch {
    return null;
  }
}

export async function saveArchivedMissions(missions: Mission[]): Promise<void> {
  await AsyncStorage.setItem(ARCHIVED_MISSIONS_KEY, JSON.stringify(missions));
}

export async function loadArchivedMissions(): Promise<Mission[]> {
  try {
    const data = await AsyncStorage.getItem(ARCHIVED_MISSIONS_KEY);
    if (!data) return [];
    return (JSON.parse(data) as any[]).map(reviveDates);
  } catch {
    return [];
  }
}
