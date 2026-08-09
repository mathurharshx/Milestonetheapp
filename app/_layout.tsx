import React, { useEffect, useState } from 'react';
import { Stack, useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import 'react-native-reanimated';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { MissionContext, useMissionReducer } from '../store/missionStore';
import { PomodoroContext } from '../store/pomodoroContext';
import { ThemeContext } from '../store/themeContext';
import { usePomodoro } from '../hooks/usePomodoro';
import { useThemeState } from '../hooks/useThemeState';
import { Splash } from '../components/Splash';

export const unstable_settings = {
  anchor: '(tabs)',
};

export default function RootLayout() {
  const missionStore = useMissionReducer();
  const pomodoroState = usePomodoro();
  const themeState = useThemeState();
  const router = useRouter();
  const [showSplash, setShowSplash] = useState(true);

  useEffect(() => {
    missionStore.loadData();
  }, []);

  useEffect(() => {
    if (!showSplash) {
      const checkOnboarding = async () => {
        try {
          const hasSeen = await AsyncStorage.getItem('milestone:hasSeenOnboarding');
          if (hasSeen !== 'true') {
            router.replace('/onboarding');
          }
        } catch (e) {
          console.error('Failed to check onboarding state:', e);
        }
      };
      checkOnboarding();
    }
  }, [showSplash, router]);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <ThemeContext.Provider value={themeState}>
        <MissionContext.Provider value={missionStore}>
          <PomodoroContext.Provider value={pomodoroState}>
            <Stack
              screenOptions={{
                headerShown: false,
                contentStyle: { backgroundColor: themeState.colors.background },
              }}
            >
              <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
              <Stack.Screen name="onboarding" options={{ headerShown: false, gestureEnabled: false }} />
            </Stack>
            
            <StatusBar style={themeState.mode === 'dark' ? 'light' : 'dark'} />
            
            {/* Custom Splash Screen Overlay */}
            {showSplash && <Splash onComplete={() => setShowSplash(false)} />}
          </PomodoroContext.Provider>
        </MissionContext.Provider>
      </ThemeContext.Provider>
    </GestureHandlerRootView>
  );
}
