import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, StyleSheet, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useRouter } from 'expo-router';
import { useTheme } from '../store/themeContext';
import { Spacing, FontSize, BorderRadius } from '../utils/theme';
import { Feather } from '@expo/vector-icons';

export default function ProfileScreen() {
  const { colors } = useTheme();
  const router = useRouter();
  const [userName, setUserName] = useState('');

  useEffect(() => {
    AsyncStorage.getItem('milestone:userName').then((n) => setUserName(n || ''));
  }, []);

  const saveUserName = async (name: string) => {
    setUserName(name);
    await AsyncStorage.setItem('milestone:userName', name);
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton} activeOpacity={0.6}>
          <Feather name="chevron-left" size={28} color={colors.textPrimary} style={{ marginLeft: -8 }} />
        </TouchableOpacity>
        <Text style={[styles.title, { color: colors.textPrimary }]}>Profile</Text>
        <View style={styles.backButton} />
      </View>

      <View style={styles.content}>
        <Text style={[styles.label, { color: colors.textSecondary }]}>YOUR NAME</Text>
        <TextInput
          style={[styles.input, { color: colors.textPrimary, backgroundColor: colors.surface }]}
          placeholder="Enter your name"
          placeholderTextColor={colors.textMuted}
          value={userName}
          onChangeText={saveUserName}
          maxLength={30}
          autoFocus
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.xl,
    paddingVertical: Spacing.lg,
  },
  backButton: {
    width: 60,
  },
  backText: {
    fontSize: FontSize.md,
    fontWeight: '500',
  },
  title: {
    fontSize: FontSize.lg,
    fontWeight: '600',
  },
  content: {
    padding: Spacing.xxl,
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
});
