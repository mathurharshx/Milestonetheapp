import SwiftUI

public struct VaultSheet: View {
    @Environment(MissionStore.self) private var missionStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateVaultMission: Bool = false
    @State private var showPaywall: Bool = false
    @State private var newVaultTitle: String = ""
    @State private var newVaultTargetDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var showSwapConfirmation: Bool = false
    @State private var missionToActivate: Mission? = nil
    @State private var currentActiveMissionToSwap: Mission? = nil

    public init() {}

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("COLD STORAGE")
                            .font(.system(size: 10, weight: .black))
                            .tracking(3)
                            .foregroundStyle(theme.accent)

                        Text("The Mission Vault")
                            .font(.system(size: 26, weight: .medium))
                            .tracking(-0.5)
                            .foregroundStyle(theme.textPrimary)
                    }

                    Spacer()

                    Button {
                        HapticsManager.shared.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if !subscriptionStore.isProUser {
                    // Locked Pro Teaser
                    VStack(spacing: 20) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.12))
                                .frame(width: 80, height: 80)

                            Image(systemName: "archivebox.circle.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(theme.accent)
                        }

                        VStack(spacing: 8) {
                            Text("Queue Future Conquests")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(theme.textPrimary)

                            Text("Store upcoming goals safely in cold storage without diluting your focus on your active mission.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Button {
                            HapticsManager.shared.impact(.medium)
                            showPaywall = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                Text("UNLOCK WITH PREMIUM")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(theme.background)
                            .padding(.horizontal, 24)
                            .frame(height: 50)
                            .background(
                                Capsule().fill(theme.accent)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)

                        Spacer()
                    }
                } else {
                    // Active Vault List
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Quick Add Box with Target Completion Date
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DEPOSIT UPCOMING MISSION")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(2)
                                    .foregroundStyle(theme.textTertiary)

                                VStack(spacing: 12) {
                                    // Title Input
                                    TextField("What is your next mission?", text: $newVaultTitle)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(theme.textPrimary)

                                    Divider().overlay(theme.divider)

                                    // Target Completion Date Row
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(theme.accent)

                                            Text("COMPLETE BY")
                                                .font(.system(size: 10, weight: .bold))
                                                .tracking(1.5)
                                                .foregroundStyle(theme.textSecondary)
                                        }

                                        Spacer()

                                        DatePicker(
                                            "",
                                            selection: $newVaultTargetDate,
                                            in: Date()...,
                                            displayedComponents: [.date]
                                        )
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .tint(theme.accent)
                                    }

                                    // Deposit Action Button
                                    Button {
                                        depositMission()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "archivebox.fill")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("DEPOSIT TO VAULT")
                                                .font(.system(size: 11, weight: .heavy))
                                                .tracking(1.5)
                                        }
                                        .foregroundStyle(newVaultTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.textTertiary : theme.background)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(
                                            Capsule()
                                                .fill(newVaultTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.surfaceLight.opacity(0.4) : theme.accent)
                                        )
                                    }
                                    .disabled(newVaultTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    .buttonStyle(.plain)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(theme.surfaceLight.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.border.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .padding(.bottom, 8)

                            if missionStore.vaultMissions.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 28))
                                        .foregroundStyle(theme.textTertiary)
                                        .padding(.top, 40)

                                    Text("The Vault is empty.")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(theme.textTertiary)

                                    Text("Add future goals above to keep them queued.")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(theme.textTertiary.opacity(0.7))
                                }
                            } else {
                                ForEach(missionStore.vaultMissions) { mission in
                                    let hasActive = missionStore.activeMission(for: mission.category) != nil
                                    VaultCard(
                                        mission: mission,
                                        theme: theme,
                                        hasActiveMission: hasActive,
                                        onUpdateTargetDate: { updatedDate in
                                            HapticsManager.shared.impact(.light)
                                            missionStore.updateVaultMissionTargetDate(id: mission.id, targetDate: updatedDate)
                                        },
                                        onActivate: {
                                            handleActivate(vaultMission: mission)
                                        },
                                        onDelete: {
                                            HapticsManager.shared.impact(.light)
                                            missionStore.deleteFromVault(id: mission.id)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
        }
        .confirmationDialog(
            "Switch Active Mission?",
            isPresented: $showSwapConfirmation,
            titleVisibility: .visible,
            presenting: missionToActivate
        ) { targetMission in
            Button("Shelve to Vault & Activate") {
                HapticsManager.shared.notification(.success)
                missionStore.swapVaultMissionWithActive(vaultMissionId: targetMission.id)
                dismiss()
            }

            Button("Mark Current Complete & Activate") {
                HapticsManager.shared.notification(.success)
                missionStore.completeCurrentAndActivateVault(vaultMissionId: targetMission.id)
                dismiss()
            }

            Button("Cancel", role: .cancel) {
                missionToActivate = nil
                currentActiveMissionToSwap = nil
            }
        } message: { targetMission in
            if let active = currentActiveMissionToSwap {
                Text("You're currently working on \"\(active.title)\". Shelving will safely move it to the Vault with all progress saved, while \"\(targetMission.title)\" becomes active.")
            } else {
                Text("Activate \"\(targetMission.title)\" now?")
            }
        }
    }

    private func handleActivate(vaultMission: Mission) {
        if let active = missionStore.activeMission(for: vaultMission.category) {
            HapticsManager.shared.impact(.medium)
            currentActiveMissionToSwap = active
            missionToActivate = vaultMission
            showSwapConfirmation = true
        } else {
            HapticsManager.shared.notification(.success)
            missionStore.promoteToActiveMission(vaultMissionId: vaultMission.id)
            dismiss()
        }
    }

    private func depositMission() {
        guard !newVaultTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        HapticsManager.shared.notification(.success)
        missionStore.addToVault(
            title: newVaultTitle,
            targetDate: newVaultTargetDate
        )
        newVaultTitle = ""
        newVaultTargetDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }
}

// ── Vault Card ──
private struct VaultCard: View {
    let mission: Mission
    let theme: ThemeTokens
    var hasActiveMission: Bool = false
    var onUpdateTargetDate: ((Date) -> Void)? = nil
    let onActivate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)

                    Text("Queued \(mission.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(theme.textTertiary)
                }

                Spacer()

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.textTertiary.opacity(0.6))
                }
            }

            // Target Completion Date Row
            HStack(spacing: 6) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.accent)

                Text("Target: \(mission.targetDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.accent)

                let daysLeft = Calendar.current.dateComponents(
                    [.day],
                    from: Calendar.current.startOfDay(for: Date()),
                    to: Calendar.current.startOfDay(for: mission.targetDate)
                ).day ?? 0

                if daysLeft >= 0 {
                    Text("(\(daysLeft == 0 ? "Today" : "\(daysLeft)d left"))")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(theme.textTertiary)
                }

                Spacer()

                // Compact DatePicker to edit target completion date
                DatePicker(
                    "",
                    selection: Binding(
                        get: { mission.targetDate },
                        set: { onUpdateTargetDate?($0) }
                    ),
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(theme.accent)
                .scaleEffect(0.85)
            }
            .padding(.vertical, 2)

            Divider().overlay(theme.divider)

            HStack {
                Text("\(mission.todos.count) tasks planned")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                Button {
                    onActivate()
                } label: {
                    HStack(spacing: 4) {
                        Text(hasActiveMission ? "SWAP" : "ACTIVATE")
                        Image(systemName: hasActiveMission ? "arrow.triangle.2.circlepath" : "arrow.up.right")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(theme.accentDim)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.border.opacity(0.3), lineWidth: 1)
        )
    }
}
