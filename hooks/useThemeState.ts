import { useState, useEffect, useCallback, useMemo } from 'react';
import { useColorScheme } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { LightColors, DarkColors, ColorPalette } from '../utils/theme';
import { ThemeMode, ThemeContextType } from '../store/themeContext';

const STORAGE_KEY = '@milestone_theme';

export function useThemeState(): ThemeContextType {
  const systemScheme = useColorScheme();
  const [mode, setMode] = useState<ThemeMode>(systemScheme === 'dark' ? 'dark' : 'light');

  // Load saved preference on mount
  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((saved) => {
      if (saved === 'light' || saved === 'dark') {
        setMode(saved);
      }
    });
  }, []);

  const toggleTheme = useCallback(() => {
    setMode((prev) => {
      const next = prev === 'light' ? 'dark' : 'light';
      AsyncStorage.setItem(STORAGE_KEY, next);
      return next;
    });
  }, []);

  const colors: ColorPalette = useMemo(
    () => (mode === 'dark' ? DarkColors : LightColors),
    [mode]
  );

  return { mode, colors, toggleTheme };
}
