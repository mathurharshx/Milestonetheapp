import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, StyleSheet, TouchableOpacity, KeyboardAvoidingView, Platform, Keyboard } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useRouter } from 'expo-router';
import Animated, { FadeIn, FadeOut, SlideInRight, SlideOutLeft } from 'react-native-reanimated';
import { useTheme } from '../store/themeContext';
import { Spacing, FontSize, BorderRadius } from '../utils/theme';

export default function OnboardingScreen() {
  const { colors } = useTheme();
  const router = useRouter();
  const [step, setStep] = useState(1);
  const [userName, setUserName] = useState('');

  const handleNext = () => {
    setStep(2);
  };

  const handleStart = async () => {
    Keyboard.dismiss();
    await AsyncStorage.setItem('milestone:userName', userName.trim() || 'Commander');
    await AsyncStorage.setItem('milestone:hasSeenOnboarding', 'true');
    router.replace('/');
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <KeyboardAvoidingView 
        style={styles.keyboardView} 
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        {step === 1 && (
          <Animated.View 
            entering={FadeIn.duration(800)} 
            exiting={SlideOutLeft.duration(400)} 
            style={styles.stepContainer}
          >
            <View style={styles.content}>
              <Text style={[styles.title, { color: colors.textPrimary }]}>MILESTONE</Text>
              <Text style={[styles.subtitle, { color: colors.textSecondary }]}>
                {"One mission.\nThat's it."}
              </Text>
              <Text style={[styles.description, { color: colors.textTertiary }]}>
                Focus on what matters. Ignore the noise. Conquering your goals begins with a single step.
              </Text>
            </View>
            <TouchableOpacity 
              style={[styles.button, { backgroundColor: colors.accent }]} 
              onPress={handleNext}
              activeOpacity={0.8}
            >
              <Text style={[styles.buttonText, { color: colors.background }]}>CONTINUE</Text>
            </TouchableOpacity>
          </Animated.View>
        )}

        {step === 2 && (
          <Animated.View 
            entering={SlideInRight.duration(400)} 
            style={styles.stepContainer}
          >
            <View style={styles.content}>
              <Text style={[styles.title, { color: colors.textPrimary, marginBottom: Spacing.xxxl }]}>SETUP</Text>
              <Text style={[styles.label, { color: colors.textSecondary }]}>WHAT SHOULD WE CALL YOU?</Text>
              <TextInput
                style={[styles.input, { color: colors.textPrimary, backgroundColor: colors.surface }]}
                placeholder="Enter your name"
                placeholderTextColor={colors.textMuted}
                value={userName}
                onChangeText={setUserName}
                maxLength={30}
                autoFocus
                returnKeyType="done"
                onSubmitEditing={handleStart}
              />
            </View>
            <TouchableOpacity 
              style={[styles.button, { backgroundColor: colors.accent }]} 
              onPress={handleStart}
              activeOpacity={0.8}
            >
              <Text style={[styles.buttonText, { color: colors.background }]}>START MISSION</Text>
            </TouchableOpacity>
          </Animated.View>
        )}
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  keyboardView: {
    flex: 1,
  },
  stepContainer: {
    flex: 1,
    padding: Spacing.xxl,
    justifyContent: 'space-between',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
  },
  title: {
    fontSize: FontSize.caption,
    fontWeight: '800',
    letterSpacing: 4,
    marginBottom: Spacing.xl,
  },
  subtitle: {
    fontSize: 42,
    fontWeight: '700',
    lineHeight: 48,
    letterSpacing: -1,
    marginBottom: Spacing.xl,
  },
  description: {
    fontSize: FontSize.lg,
    lineHeight: 28,
    fontWeight: '400',
  },
  label: {
    fontSize: FontSize.xs,
    fontWeight: '600',
    letterSpacing: 2,
    marginBottom: Spacing.md,
  },
  input: {
    fontSize: FontSize.xl,
    padding: Spacing.lg,
    borderRadius: BorderRadius.md,
    fontWeight: '400',
  },
  button: {
    height: 56,
    borderRadius: BorderRadius.sm,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.xl,
  },
  buttonText: {
    fontSize: FontSize.sm,
    fontWeight: '700',
    letterSpacing: 2,
  },
});
