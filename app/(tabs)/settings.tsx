import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Switch,
  TouchableOpacity,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useRouter, useFocusEffect } from 'expo-router';
import { useTheme } from '../../store/themeContext';
import { Spacing, FontSize, BorderRadius, ColorPalette } from '../../utils/theme';
import { setHapticsEnabled, triggerHaptic } from '../../utils/haptics';
import { Feather } from '@expo/vector-icons';

export default function SettingsScreen() {
  const { mode, colors, toggleTheme } = useTheme();
  const [userName, setUserName] = useState('');
  const [hapticsOn, setHapticsOn] = useState(true);
  const router = useRouter();

  useFocusEffect(
    useCallback(() => {
      AsyncStorage.getItem('milestone:userName').then((n) => setUserName(n || ''));
      AsyncStorage.getItem('milestone:haptics').then((h) => {
        if (h !== null) setHapticsOn(h === 'true');
      });
    }, [])
  );

  const saveUserName = async (name: string) => {
    setUserName(name);
    await AsyncStorage.setItem('milestone:userName', name);
  };

  const toggleHaptics = () => {
    const nextState = !hapticsOn;
    setHapticsOn(nextState);
    setHapticsEnabled(nextState);
  };

  const s = makeStyles(colors);

  return (
    <SafeAreaView style={[s.container, { backgroundColor: colors.background }]}>
      {/* Header */}
      <View style={s.header}>
        <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: Spacing.xxl }}>
          <TouchableOpacity onPress={() => router.push('/')} style={{ width: 40 }} activeOpacity={0.6}>
            <Feather name="chevron-left" size={28} color={colors.accent} style={{ marginLeft: -8 }} />
          </TouchableOpacity>
          <Text style={[s.brand, { color: colors.accent, marginBottom: 0 }]}>MILESTONE</Text>
        </View>
        <Text style={[s.headerTitle, { color: colors.textPrimary }]}>Settings</Text>
      </View>

      <ScrollView
        contentContainerStyle={s.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Profile */}
        <SettingsRow
          colors={colors}
          label="Profile"
          sublabel={userName || 'Set your name'}
          showChevron
          onPress={() => router.push('/profile')}
        />

        {/* Appearance — functional toggle */}
        <View style={[s.row, { borderBottomColor: colors.divider }]}>
          <View>
            <Text style={[s.rowLabel, { color: colors.textPrimary }]}>Appearance</Text>
            <Text style={[s.rowSublabel, { color: colors.textTertiary }]}>
              {mode === 'dark' ? 'Dark' : 'Light'}
            </Text>
          </View>
          <Switch
            value={mode === 'dark'}
            onValueChange={() => {
              triggerHaptic();
              toggleTheme();
            }}
          />
        </View>

        {/* Haptics */}
        <SettingsRow
          colors={colors}
          label="Haptics"
          sublabel={hapticsOn ? 'On' : 'Off'}
          onPress={toggleHaptics}
        />

        {/* About */}
        <SettingsRow
          colors={colors}
          label="About"
          sublabel="v1.0.0"
        />
      </ScrollView>
    </SafeAreaView>
  );
}

function SettingsRow({
  colors,
  label,
  sublabel,
  showChevron,
  disabled,
  onPress,
}: {
  colors: ColorPalette;
  label: string;
  sublabel?: string;
  showChevron?: boolean;
  disabled?: boolean;
  onPress?: () => void;
}) {
  return (
    <TouchableOpacity
      style={[rowStyles.row, { borderBottomColor: colors.divider }, disabled && { opacity: 0.4 }]}
      activeOpacity={0.6}
      disabled={disabled || (!onPress && !showChevron)}
      onPress={onPress}
    >
      <View>
        <Text style={[rowStyles.label, { color: colors.textPrimary }]}>{label}</Text>
        {sublabel && (
          <Text style={[rowStyles.sublabel, { color: colors.textTertiary }]}>{sublabel}</Text>
        )}
      </View>
      {showChevron && (
        <Text style={[rowStyles.chevron, { color: colors.textMuted }]}>›</Text>
      )}
    </TouchableOpacity>
  );
}

const rowStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
  },
  label: {
    fontSize: FontSize.md,
    fontWeight: '500',
  },
  sublabel: {
    fontSize: FontSize.xs,
    fontWeight: '400',
    marginTop: 2,
  },
  chevron: {
    fontSize: 22,
    fontWeight: '300',
  },
});

function makeStyles(colors: ColorPalette) {
  return StyleSheet.create({
    container: {
      flex: 1,
    },
    header: {
      paddingHorizontal: Spacing.xxl,
      paddingTop: Spacing.lg,
      paddingBottom: Spacing.xl,
    },
    brand: {
      fontSize: FontSize.caption,
      fontWeight: '800',
      letterSpacing: 4,
      marginBottom: Spacing.xxl,
    },
    headerTitle: {
      fontSize: 36,
      fontWeight: '200',
      letterSpacing: -1,
    },
    scrollContent: {
      paddingHorizontal: Spacing.xxl,
      paddingBottom: 140,
    },
    row: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      paddingVertical: Spacing.lg,
      borderBottomWidth: 1,
    },
    rowLabel: {
      fontSize: FontSize.md,
      fontWeight: '500',
    },
    rowSublabel: {
      fontSize: FontSize.xs,
      fontWeight: '400',
      marginTop: 2,
    },
  });
}
