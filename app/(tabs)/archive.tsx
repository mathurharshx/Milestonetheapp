import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Animated,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useMissionContext, Mission } from '../../store/missionStore';
import { formatDate, formatDuration } from '../../utils/dateCalculations';
import { Spacing, FontSize, BorderRadius } from '../../utils/theme';
import { useTheme } from '../../store/themeContext';

export default function ArchiveScreen() {
  const { colors } = useTheme();
  const { state, deleteArchivedMissions } = useMissionContext();
  const { archivedMissions } = state;
  const [isEditing, setIsEditing] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  const toggleSelect = useCallback((id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }, []);

  const handleDelete = useCallback(() => {
    if (selectedIds.size === 0) return;
    const count = selectedIds.size;
    Alert.alert(
      'Delete Missions',
      `Remove ${count} mission${count > 1 ? 's' : ''} from archive?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            await deleteArchivedMissions(Array.from(selectedIds));
            setSelectedIds(new Set());
            setIsEditing(false);
          },
        },
      ]
    );
  }, [selectedIds, deleteArchivedMissions]);

  const exitEdit = useCallback(() => {
    setIsEditing(false);
    setSelectedIds(new Set());
  }, []);

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerTop}>
          <View>
            <Text style={[styles.brand, { color: colors.accent }]}>MILESTONE</Text>
            <Text style={[styles.headerTitle, { color: colors.textPrimary }]}>Archive</Text>
          </View>
          {archivedMissions.length > 0 && (
            <TouchableOpacity
              onPress={isEditing ? exitEdit : () => setIsEditing(true)}
              activeOpacity={0.7}
              style={{ marginRight: 48, marginTop: 4 }}
            >
              <Text style={[styles.editButton, { color: colors.accent }]}>
                {isEditing ? 'DONE' : 'EDIT'}
              </Text>
            </TouchableOpacity>
          )}
        </View>
        {archivedMissions.length > 0 && !isEditing && (
          <Text style={[styles.headerCount, { color: colors.textTertiary }]}>
            {archivedMissions.length} completed
          </Text>
        )}
        {isEditing && selectedIds.size > 0 && (
          <Text style={[styles.headerCount, { color: colors.textTertiary }]}>
            {selectedIds.size} selected
          </Text>
        )}
      </View>

      {archivedMissions.length === 0 ? (
        <View style={styles.emptyContainer}>
          <View style={[styles.emptyCircle, { borderColor: colors.border }]}>
            <Text style={[styles.emptyDash, { color: colors.textMuted }]}>—</Text>
          </View>
          <Text style={[styles.emptyTitle, { color: colors.textSecondary }]}>No missions yet</Text>
          <Text style={[styles.emptySubtitle, { color: colors.textTertiary }]}>
            Completed missions appear here
          </Text>
        </View>
      ) : (
        <>
          <FlatList
            data={archivedMissions}
            keyExtractor={(item) => item.id}
            contentContainerStyle={styles.listContent}
            showsVerticalScrollIndicator={false}
            renderItem={({ item, index }) => (
              <ArchiveCard
                mission={item}
                index={index}
                isEditing={isEditing}
                isSelected={selectedIds.has(item.id)}
                onSelect={toggleSelect}
              />
            )}
            extraData={[isEditing, selectedIds]}
          />

          {/* Delete bar */}
          {isEditing && selectedIds.size > 0 && (
            <View style={styles.deleteBar}>
              <TouchableOpacity
                style={[styles.deleteButton, { backgroundColor: colors.danger }]}
                onPress={handleDelete}
                activeOpacity={0.7}
              >
                <Text style={[styles.deleteButtonText, { color: colors.background }]}>
                  DELETE ({selectedIds.size})
                </Text>
              </TouchableOpacity>
            </View>
          )}
        </>
      )}
    </SafeAreaView>
  );
}

function ArchiveCard({
  mission,
  index,
  isEditing,
  isSelected,
  onSelect,
}: {
  mission: Mission;
  index: number;
  isEditing: boolean;
  isSelected: boolean;
  onSelect: (id: string) => void;
}) {
  const { colors } = useTheme();
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(20)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 500,
        delay: index * 80,
        useNativeDriver: true,
      }),
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 500,
        delay: index * 80,
        useNativeDriver: true,
      }),
    ]).start();
  }, []);

  const duration = mission.completedAt
    ? formatDuration(mission.createdAt, mission.completedAt)
    : '—';

  const content = (
    <Animated.View
      style={[
        styles.card,
        { borderBottomColor: colors.divider },
        {
          opacity: fadeAnim,
          transform: [{ translateY: slideAnim }],
        },
      ]}
    >
      <View style={styles.cardRow}>
        {/* Selection circle */}
        {isEditing && (
          <View
            style={[
              styles.selectCircle,
              { borderColor: colors.textTertiary },
              isSelected && { borderColor: colors.accent, backgroundColor: colors.accent },
            ]}
          >
            {isSelected && <Text style={[styles.selectCheck, { color: colors.background }]}>✓</Text>}
          </View>
        )}

        <View style={styles.cardContent}>
          {/* Top row: title + badge */}
          <View style={styles.cardTop}>
            <Text style={[styles.cardTitle, { color: colors.textPrimary }]} numberOfLines={2}>{mission.title}</Text>
            {!isEditing && <Text style={[styles.checkBadge, { color: colors.accent }]}>✓</Text>}
          </View>

          {mission.note ? (
            <Text style={[styles.cardNote, { color: colors.textTertiary }]} numberOfLines={2}>{mission.note}</Text>
          ) : null}

          {/* Divider */}
          <View style={[styles.cardDivider, { backgroundColor: colors.divider }]} />

          {/* Details row */}
          <View style={styles.cardDetails}>
            <DetailItem label="STARTED" value={formatDate(mission.createdAt)} colors={colors} />
            <DetailItem label="COMPLETED" value={mission.completedAt ? formatDate(mission.completedAt) : '—'} colors={colors} />
            <DetailItem label="DURATION" value={duration} colors={colors} />
          </View>
        </View>
      </View>
    </Animated.View>
  );

  if (isEditing) {
    return (
      <TouchableOpacity
        activeOpacity={0.7}
        onPress={() => onSelect(mission.id)}
      >
        {content}
      </TouchableOpacity>
    );
  }

  return content;
}

function DetailItem({ label, value, colors }: { label: string; value: string; colors: any }) {
  return (
    <View style={styles.detailItem}>
      <Text style={[styles.detailLabel, { color: colors.textTertiary }]}>{label}</Text>
      <Text style={[styles.detailValue, { color: colors.textSecondary }]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: Spacing.xxl,
    paddingTop: Spacing.lg,
    paddingBottom: Spacing.xl,
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
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
  headerCount: {
    fontSize: FontSize.sm,
    fontWeight: '400',
    marginTop: Spacing.xs,
  },
  editButton: {
    fontSize: FontSize.caption,
    fontWeight: '600',
    letterSpacing: 2,
    marginTop: Spacing.xs,
  },

  // Empty state
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing.xxl,
  },
  emptyCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    borderWidth: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.xxl,
  },
  emptyDash: {
    fontSize: FontSize.xl,
    fontWeight: '200',
  },
  emptyTitle: {
    fontSize: FontSize.lg,
    fontWeight: '400',
    marginBottom: Spacing.sm,
  },
  emptySubtitle: {
    fontSize: FontSize.sm,
  },

  // List
  listContent: {
    paddingHorizontal: Spacing.xxl,
    paddingBottom: 140,
  },

  // Card
  card: {
    borderBottomWidth: 1,
    paddingVertical: Spacing.xl,
  },
  cardRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  cardContent: {
    flex: 1,
  },
  cardTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  cardTitle: {
    fontSize: FontSize.lg,
    fontWeight: '500',
    flex: 1,
    marginRight: Spacing.lg,
  },
  checkBadge: {
    fontSize: FontSize.md,
    fontWeight: '400',
  },
  cardNote: {
    fontSize: FontSize.sm,
    marginTop: Spacing.sm,
    lineHeight: 20,
  },
  cardDivider: {
    height: 1,
    marginVertical: Spacing.lg,
  },
  cardDetails: {
    flexDirection: 'row',
  },
  detailItem: {
    flex: 1,
  },
  detailLabel: {
    fontSize: 9,
    fontWeight: '600',
    letterSpacing: 1.5,
    marginBottom: 4,
  },
  detailValue: {
    fontSize: FontSize.sm,
    fontWeight: '400',
  },

  // Selection
  selectCircle: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 1.5,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
    marginTop: 2,
  },
  selectCheck: {
    fontSize: 12,
    fontWeight: '700',
  },

  // Delete bar
  deleteBar: {
    position: 'absolute',
    bottom: 96,
    left: Spacing.xxl,
    right: Spacing.xxl,
  },
  deleteButton: {
    height: 52,
    borderRadius: BorderRadius.xl,
    justifyContent: 'center',
    alignItems: 'center',
  },
  deleteButtonText: {
    fontSize: FontSize.xs,
    fontWeight: '700',
    letterSpacing: 3,
  },
});
