import * as Haptics from 'expo-haptics';
import AsyncStorage from '@react-native-async-storage/async-storage';

let isHapticsEnabled = true;

// Initialize on app start
AsyncStorage.getItem('milestone:haptics').then((val) => {
  if (val !== null) {
    isHapticsEnabled = val === 'true';
  }
});

export const setHapticsEnabled = (enabled: boolean) => {
  isHapticsEnabled = enabled;
  AsyncStorage.setItem('milestone:haptics', String(enabled));
  
  if (enabled) {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  }
};

export const getHapticsEnabled = () => isHapticsEnabled;

export const triggerHaptic = (style: Haptics.ImpactFeedbackStyle = Haptics.ImpactFeedbackStyle.Light) => {
  if (isHapticsEnabled) {
    Haptics.impactAsync(style);
  }
};
