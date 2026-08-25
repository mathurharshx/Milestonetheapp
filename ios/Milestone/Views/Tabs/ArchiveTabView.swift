import SwiftUI

public struct ArchiveTabView: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(\.theme) private var theme

    @State private var isEditing: Bool = false
    @State private var selectedIds: Set<String> = []
    @State private var showDeleteConfirmation: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MILESTONE")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(4)
                                .foregroundStyle(theme.accent)

                            Text("Archive")
                                .font(.system(size: 36, weight: .light))
                                .tracking(-1)
                                .foregroundStyle(theme.textPrimary)
                        }

                        Spacer()

                        if !missionStore.archivedMissions.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if isEditing {
                                        isEditing = false
                                        selectedIds.removeAll()
                                    } else {
                                        isEditing = true
                                    }
                                }
                            } label: {
                                Text(isEditing ? "DONE" : "EDIT")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(2)
                                    .foregroundStyle(theme.accent)
                                    .padding(.top, 8)
                            }
                        }
                    }

                    if !missionStore.archivedMissions.isEmpty {
                        Text(isEditing && !selectedIds.isEmpty
                             ? "\(selectedIds.count) selected"
                             : "\(missionStore.archivedMissions.count) completed")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(theme.textTertiary)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Content
                if missionStore.archivedMissions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()

                        Circle()
                            .stroke(theme.border, lineWidth: 1)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text("—")
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundStyle(theme.textMuted)
                            )
                            .padding(.bottom, 8)

                        Text("No missions yet")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(theme.textSecondary)

                        Text("Completed missions appear here")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(theme.textTertiary)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(missionStore.archivedMissions) { mission in
                                ArchiveCardView(
                                    mission: mission,
                                    isEditing: isEditing,
                                    isSelected: selectedIds.contains(mission.id),
                                    onSelect: {
                                        if selectedIds.contains(mission.id) {
                                            selectedIds.remove(mission.id)
                                        } else {
                                            selectedIds.insert(mission.id)
                                        }
                                    }
                                )
                                .scrollTransition(.interactive) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.8)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.98)
                                }

                                Divider()
                                    .overlay(theme.divider)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    .scrollIndicators(.hidden)
                }
            }

            // Floating Delete Bar in Edit Mode
            if isEditing && !selectedIds.isEmpty {
                VStack {
                    Spacer()

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Text("DELETE (\(selectedIds.count))")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.danger)
                            )
                            .shadow(color: theme.danger.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .confirmationDialog(
            "Delete Missions",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                HapticsManager.shared.notification(.warning)
                missionStore.deleteArchived(ids: selectedIds)
                selectedIds.removeAll()
                isEditing = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove \(selectedIds.count) mission\(selectedIds.count > 1 ? "s" : "") from archive?")
        }
    }
}

private struct ArchiveCardView: View {
    let mission: Mission
    let isEditing: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button {
            if isEditing {
                HapticsManager.shared.selection()
                onSelect()
            }
        } label: {
            HStack(alignment: .top, spacing: 16) {
                // Multi-select circle
                if isEditing {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? theme.accent : theme.textTertiary, lineWidth: 1.5)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(theme.accent)
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme.background)
                        }
                    }
                    .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 10) {
                    // Top Row: Title + checkmark
                    HStack(alignment: .top) {
                        Text(mission.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if !isEditing {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(theme.accent)
                        }
                    }

                    if let note = mission.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(theme.textTertiary)
                            .lineLimit(2)
                    }

                    Divider()
                        .overlay(theme.divider)

                    // Details row: STARTED / COMPLETED / DURATION
                    HStack(spacing: 12) {
                        DetailItemView(label: "STARTED", value: DateCalculations.formatDate(mission.createdAt))
                        DetailItemView(
                            label: "COMPLETED",
                            value: mission.completedAt != nil ? DateCalculations.formatDate(mission.completedAt!) : "—"
                        )
                        DetailItemView(
                            label: "DURATION",
                            value: mission.completedAt != nil ? DateCalculations.formatDuration(startDate: mission.createdAt, endDate: mission.completedAt!) : "—"
                        )
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

private struct DetailItemView: View {
    let label: String
    let value: String
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(theme.textTertiary)

            Text(value)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
