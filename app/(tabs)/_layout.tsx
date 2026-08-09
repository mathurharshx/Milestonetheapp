import { Tabs } from 'expo-router';
import React from 'react';
import GlassTabBar from '../../components/GlassTabBar';
import SettingsButton from '../../components/SettingsButton';
import { useTheme } from '../../store/themeContext';

export default function TabLayout() {
  const { colors } = useTheme();

  return (
    <>
      <Tabs
        screenOptions={{
          headerShown: false,
          tabBarStyle: { display: 'none' },
          tabBarActiveTintColor: colors.accent,
        }}
      >
        <Tabs.Screen name="index" options={{ title: 'Mission' }} />
        <Tabs.Screen name="pomodoro" options={{ title: 'Pomodoro' }} />
        <Tabs.Screen name="archive" options={{ title: 'Archive' }} />
        <Tabs.Screen name="settings" options={{ href: null }} />
      </Tabs>

      {/* Persistent overlays */}
      <SettingsButton />
      <GlassTabBar />
    </>
  );
}
