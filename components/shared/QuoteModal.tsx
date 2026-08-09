import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
} from 'react-native';
import { BlurView } from 'expo-blur';
import Animated, { FadeIn, FadeInDown, FadeInUp, ZoomIn } from 'react-native-reanimated';
import { Quote } from '../../utils/quotes';
import { Spacing, FontSize, BorderRadius } from '../../utils/theme';
import { useTheme } from '../../store/themeContext';

interface QuoteModalProps {
  visible: boolean;
  quote: Quote | null;
  onContinue: () => void;
}

export default function QuoteModal({ visible, quote, onContinue }: QuoteModalProps) {
  const { colors, mode } = useTheme();

  if (!quote) return null;

  return (
    <Modal visible={visible} transparent animationType="fade">
      <BlurView 
        intensity={mode === 'dark' ? 70 : 40} 
        tint={mode === 'dark' ? 'dark' : 'light'} 
        style={styles.overlay}
      >
        <Animated.View 
          entering={FadeIn.duration(600)} 
          style={styles.content}
        >
          {/* Checkmark */}
          <Animated.View
            entering={FadeIn.duration(600).delay(200)}
            style={[
              styles.checkmarkContainer,
              { borderColor: colors.accent }
            ]}
          >
            <Text style={[styles.checkmark, { color: colors.accent }]}>✓</Text>
          </Animated.View>

          <Animated.Text 
            entering={FadeIn.duration(600).delay(300)}
            style={[styles.title, { color: colors.textPrimary }]}
          >
            MISSION COMPLETE
          </Animated.Text>

          {/* Divider */}
          <Animated.View
            entering={FadeIn.duration(600).delay(400)}
            style={[
              styles.divider,
              { backgroundColor: colors.divider }
            ]}
          />

          {/* Quote */}
          <Animated.View 
            entering={FadeIn.duration(600).delay(500)}
            style={styles.quoteContainer}
          >
            <Text style={[styles.quoteText, { color: colors.textSecondary }]}>{"“"}{quote.text}{"”"}</Text>
            <Text style={[styles.quoteAuthor, { color: colors.textTertiary }]}>{quote.author}</Text>
          </Animated.View>

          <Animated.View entering={FadeIn.duration(600).delay(800)}>
            <TouchableOpacity
              style={[styles.continueButton, { borderColor: colors.accent }]}
              onPress={onContinue}
              activeOpacity={0.7}
            >
              <Text style={[styles.continueText, { color: colors.accent }]}>CONTINUE</Text>
            </TouchableOpacity>
          </Animated.View>
        </Animated.View>
      </BlurView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing.xxl,
  },
  content: {
    alignItems: 'center',
    width: '100%',
    maxWidth: 320,
  },
  checkmarkContainer: {
    width: 72,
    height: 72,
    borderRadius: 36,
    borderWidth: 2,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.xxl,
  },
  checkmark: {
    fontSize: 32,
    fontWeight: '300',
  },
  title: {
    fontSize: FontSize.sm,
    fontWeight: '700',
    letterSpacing: 6,
    marginBottom: Spacing.xl,
  },
  divider: {
    height: 1,
    width: '40%',
    marginBottom: Spacing.xxl,
  },
  quoteContainer: {
    marginBottom: Spacing.xxxl,
    paddingHorizontal: Spacing.sm,
  },
  quoteText: {
    fontSize: FontSize.lg,
    fontWeight: '300',
    textAlign: 'center',
    lineHeight: 28,
    marginBottom: Spacing.lg,
  },
  quoteAuthor: {
    fontSize: FontSize.sm,
    fontWeight: '500',
    textAlign: 'center',
    letterSpacing: 2,
    textTransform: 'uppercase',
  },
  continueButton: {
    height: 48,
    paddingHorizontal: 48,
    borderWidth: 1,
    borderRadius: BorderRadius.xl,
    justifyContent: 'center',
    alignItems: 'center',
  },
  continueText: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    letterSpacing: 3,
  },
});
