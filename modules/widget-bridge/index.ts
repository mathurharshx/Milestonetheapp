import { NativeModule, requireNativeModule, Platform } from 'expo-modules-core';

interface WidgetBridgeModuleType extends NativeModule {
  setSharedData(key: string, value: string): void;
  getSharedData(key: string): string | null;
  reloadWidget(): void;
}

const isIOS = Platform.OS === 'ios';

// Only load native module on iOS; provide no-ops for Android
let nativeModule: WidgetBridgeModuleType | null = null;
if (isIOS) {
  try {
    nativeModule = requireNativeModule<WidgetBridgeModuleType>('WidgetBridge');
  } catch (error) {
    console.warn("WidgetBridge native module not found. Widget sync will be disabled. (Are you running in Expo Go?)");
  }
}

/**
 * Write a JSON string to shared UserDefaults (App Group suite).
 * No-op on Android.
 */
export function setSharedData(key: string, value: string): void {
  nativeModule?.setSharedData(key, value);
}

/**
 * Read a string from shared UserDefaults.
 * Returns null on Android.
 */
export function getSharedData(key: string): string | null {
  return nativeModule?.getSharedData(key) ?? null;
}

/**
 * Trigger WidgetCenter.shared.reloadAllTimelines().
 * No-op on Android.
 */
export function reloadWidget(): void {
  nativeModule?.reloadWidget();
}
