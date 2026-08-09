import { createContext, useContext } from 'react';
import { ColorPalette, LightColors } from '../utils/theme';

export type ThemeMode = 'light' | 'dark';

export interface ThemeContextType {
  mode: ThemeMode;
  colors: ColorPalette;
  toggleTheme: () => void;
}

export const ThemeContext = createContext<ThemeContextType>({
  mode: 'light',
  colors: LightColors,
  toggleTheme: () => {},
});

export function useTheme() {
  return useContext(ThemeContext);
}
