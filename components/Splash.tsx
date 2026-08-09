import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { 
  runOnJS, 
  useAnimatedStyle, 
  useSharedValue, 
  withTiming, 
  withDelay,
  Easing
} from 'react-native-reanimated';
import * as SplashScreen from 'expo-splash-screen';
import { useTheme } from '../store/themeContext';

// Keep the splash screen visible while we render our custom splash
SplashScreen.preventAutoHideAsync().catch(() => {});

interface SplashProps {
  onComplete: () => void;
}

export function Splash({ onComplete }: SplashProps) {
  const { mode } = useTheme();
  const isDark = mode === 'dark';

  const backgroundColor = isDark ? '#222222' : '#F2F2F7';
  const textColor = isDark ? '#F2F2F7' : '#222222';
  
  // Independent animation drivers
  const titleOpacity = useSharedValue(1);
  const mainOpacity = useSharedValue(1);
  const mainTranslateY = useSharedValue(0);
  const bgOpacity = useSharedValue(1);

  useEffect(() => {
    // Hide the native splash screen as soon as this component mounts
    SplashScreen.hideAsync().catch(() => {});
    
    const easeInOut = Easing.inOut(Easing.ease);

    // 1. After ~1 second (1000ms), title fades out quickly
    titleOpacity.value = withDelay(1000, withTiming(0, { duration: 200, easing: easeInOut }));

    // 2. Then (at 1200ms), main text fades smoothly and shifts upward slightly
    mainOpacity.value = withDelay(1200, withTiming(0, { duration: 350, easing: easeInOut }));
    mainTranslateY.value = withDelay(1200, withTiming(-8, { duration: 350, easing: easeInOut }));
    
    // 3. At the exact same time, background fades to 0, crossfading to app underneath
    bgOpacity.value = withDelay(1200, withTiming(0, { duration: 400, easing: easeInOut }, (finished) => {
      if (finished) {
        runOnJS(onComplete)();
      }
    }));
  }, [onComplete]);

  const bgStyle = useAnimatedStyle(() => ({
    opacity: bgOpacity.value,
    backgroundColor,
  }));

  const titleStyle = useAnimatedStyle(() => ({
    opacity: titleOpacity.value,
  }));

  const mainStyle = useAnimatedStyle(() => ({
    opacity: mainOpacity.value,
    transform: [{ translateY: mainTranslateY.value }]
  }));

  return (
    <Animated.View style={[styles.container, bgStyle]} pointerEvents="none">
      <Animated.View style={[styles.topContainer, titleStyle]}>
        <Text style={[styles.title, { color: textColor }]}>MILESTONE</Text>
      </Animated.View>
      
      <Animated.View style={[styles.centerContainer, mainStyle]}>
        <Text style={[styles.mainText, { color: textColor }]}>
          {"One mission.\nThat's it."}
        </Text>
      </Animated.View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 9999, // Ensures it covers the entire app
    alignItems: 'center',
    justifyContent: 'center',
  },
  topContainer: {
    position: 'absolute',
    top: 100, // Generous whitespace at the top
    alignItems: 'center',
    width: '100%',
  },
  title: {
    fontSize: 13,
    letterSpacing: 6, // Subtle, slightly spaced lettering
    fontWeight: '500',
    opacity: 0.65, // Less dominant than main text
    fontFamily: 'System', 
  },
  centerContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  mainText: {
    fontSize: 34,
    fontWeight: '700', // Bold, large typography
    lineHeight: 38, // Tight line height,
    textAlign: 'center',
    fontFamily: 'System',
    letterSpacing: -0.5,
  }
});
