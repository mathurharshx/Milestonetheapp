import { BlurView } from 'expo-blur';
import { useRouter, usePathname } from 'expo-router';
import React, { useEffect, useRef } from 'react';
import {
  Animated,
  Dimensions,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../store/themeContext';

const TABS = [
  { name: 'Mission', route: '/' },
  { name: 'Pomodoro', route: '/pomodoro' },
  { name: 'Archive', route: '/archive' },
];

const SCREEN_WIDTH = Dimensions.get('window').width;
const H_PADDING = 16; // horizontal padding on each side of the bar
const BAR_WIDTH = SCREEN_WIDTH - H_PADDING * 2;
const PILL_WIDTH = BAR_WIDTH / TABS.length;

function getIndex(pathname: string) {
  if (pathname === '/' || pathname === '/index') return 0;
  if (pathname.includes('pomodoro')) return 1;
  if (pathname.includes('archive')) return 2;
  return 0;
}

export default function GlassTabBar() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const pathname = usePathname();
  const { mode, colors } = useTheme();
  const activeIndex = getIndex(pathname);

  const slideAnim = useRef(new Animated.Value(activeIndex * PILL_WIDTH)).current;

  useEffect(() => {
    Animated.spring(slideAnim, {
      toValue: activeIndex * PILL_WIDTH,
      useNativeDriver: true,
      tension: 68,
      friction: 11,
    }).start();
  }, [activeIndex]);

  const barHeight = 52;
  const bottomPad = Math.max(insets.bottom, 8);

  return (
    <View style={[styles.wrapper, { paddingBottom: bottomPad }]}>
      {/* Outer glass shell */}
      <View style={[styles.bar, { width: BAR_WIDTH, height: barHeight, borderColor: colors.border }]}>
        {/* Frosted blur layer */}
        <BlurView
          intensity={Platform.OS === 'ios' ? 70 : 40}
          tint={mode === 'dark' ? 'dark' : 'light'}
          style={StyleSheet.absoluteFill}
        />

        {/* Subtle inner border */}
        <View style={[StyleSheet.absoluteFill, styles.innerBorder, { borderColor: colors.border }]} />

        {/* Sliding pill */}
        <Animated.View
          style={[
            styles.pill,
            {
              width: PILL_WIDTH,
              height: barHeight - 8,
              transform: [{ translateX: slideAnim }],
            },
          ]}
        >
          {/* Blur layer for the pill */}
          <BlurView
            intensity={Platform.OS === 'ios' ? 85 : 55}
            tint={mode === 'dark' ? 'light' : 'dark'}
            style={[StyleSheet.absoluteFill, styles.pillBlur]}
          />
          
          {/* Subtle themed accent color overlay to bind to the app's theme */}
          <View style={[StyleSheet.absoluteFill, { backgroundColor: colors.accent, opacity: mode === 'dark' ? 0.08 : 0.15 }]} />
          
          {/* Highlight and Accent Border */}
          <View style={[StyleSheet.absoluteFill, styles.pillHighlight, { borderColor: colors.accent + '40' }]} />
        </Animated.View>

        {/* Tab labels */}
        <View style={styles.labelsRow}>
          {TABS.map((tab, i) => {
            const isActive = i === activeIndex;
            return (
              <Pressable
                key={tab.route}
                style={styles.tabItem}
                onPress={() => router.push(tab.route as any)}
                android_ripple={null}
              >
                <Text
                  style={[
                    styles.label,
                    {
                      color: isActive
                        ? (mode === 'dark' ? '#1a1a1a' : '#F2F2F7') // contrast against light/dark pill
                        : colors.textSecondary,
                    },
                  ]}
                  numberOfLines={1}
                >
                  {tab.name.toUpperCase()}
                </Text>
              </Pressable>
            );
          })}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    alignItems: 'center',
  },
  bar: {
    borderRadius: 32,
    overflow: 'hidden',
    borderWidth: 0.5,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.25,
        shadowRadius: 16,
      },
      android: { elevation: 12 },
    }),
  },
  innerBorder: {
    borderRadius: 32,
    borderWidth: 0.5,
  },
  pill: {
    position: 'absolute',
    top: 4,
    left: 4,
    borderRadius: 28,
    overflow: 'hidden',
  },
  pillBlur: {
    borderRadius: 28,
  },
  pillHighlight: {
    borderRadius: 28,
    borderWidth: 1,
  },
  labelsRow: {
    flexDirection: 'row',
    flex: 1,
    alignItems: 'center',
  },
  tabItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    height: '100%',
  },
  label: {
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 1.8,
  },
});
