export type ColorPalette = { [K in keyof typeof LightColors]: string };

export const LightColors = {
  // Backgrounds — cool grey
  background: '#F2F2F7',
  surface: '#E5E5EA',
  surfaceLight: '#D1D1D6',
  surfaceAlt: '#FFFFFF',

  // Text — dark charcoal
  textPrimary: '#222222',
  textSecondary: 'rgba(34, 34, 34, 0.6)',
  textTertiary: 'rgba(34, 34, 34, 0.35)',
  textMuted: 'rgba(34, 34, 34, 0.18)',

  // Accent — warm charcoal
  accent: '#222222',
  accentDim: 'rgba(34, 34, 34, 0.1)',
  accentMuted: 'rgba(34, 34, 34, 0.05)',

  // Dots
  dotFilled: 'rgba(34, 34, 34, 0.8)',
  dotElapsed: 'rgba(34, 34, 34, 0.15)',
  dotEmpty: 'rgba(34, 34, 34, 0.08)',

  // Utility
  danger: '#c0392b',
  border: 'rgba(34, 34, 34, 0.08)',
  divider: 'rgba(34, 34, 34, 0.05)',
} as const;

export const DarkColors: ColorPalette = {
  // Backgrounds — reversed from bright mode (dark charcoal)
  background: '#222222',
  surface: '#2a2a2a',
  surfaceLight: '#333333',
  surfaceAlt: '#1a1a1a',

  // Text — reversed from bright mode (cool grey)
  textPrimary: '#F2F2F7',
  textSecondary: 'rgba(242, 242, 247, 0.6)',
  textTertiary: 'rgba(242, 242, 247, 0.35)',
  textMuted: 'rgba(242, 242, 247, 0.18)',

  // Accent — reversed from bright mode (cool grey)
  accent: '#F2F2F7',
  accentDim: 'rgba(242, 242, 247, 0.1)',
  accentMuted: 'rgba(242, 242, 247, 0.05)',

  // Dots
  dotFilled: 'rgba(242, 242, 247, 0.8)',
  dotElapsed: 'rgba(242, 242, 247, 0.15)',
  dotEmpty: 'rgba(242, 242, 247, 0.08)',

  // Utility
  danger: '#c0392b',
  border: 'rgba(242, 242, 247, 0.08)',
  divider: 'rgba(242, 242, 247, 0.05)',
};

// Default export — components that import Colors will get the light palette.
// Components using ThemeContext will get the correct palette dynamically.
export const Colors = LightColors;

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 48,
  xxxxl: 64,
} as const;

export const FontSize = {
  caption: 11,
  xs: 12,
  sm: 13,
  md: 15,
  lg: 17,
  xl: 22,
  xxl: 28,
  hero: 56,
  mega: 72,
} as const;

export const BorderRadius = {
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  full: 9999,
} as const;

export const FontWeight = {
  light: '200' as const,
  regular: '400' as const,
  medium: '500' as const,
  semibold: '600' as const,
  bold: '700' as const,
  heavy: '800' as const,
};
