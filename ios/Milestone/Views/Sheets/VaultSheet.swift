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
                            // Quick Add Box
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DEPOSIT UPCOMING MISSION")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(2)
                                    .foregroundStyle(theme.textTertiary)

                                HStack {
                                    TextField("What is your next mission?", text: $newVaultTitle)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(theme.textPrimary)

                                    if !newVaultTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Button {
                                            depositMission()
                                        } label: {
                                            Text("DEPOSIT")
                                                .font(.system(size: 11, weight: .bold))
                                                .tracking(1)
                                                .foregroundStyle(theme.background)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Capsule().fill(theme.accent))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(theme.surfaceLight.opacity(0.5))
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
                                    VaultCard(mission: mission, theme: theme) {
                                        // Activate Now
                                        HapticsManager.shared.notification(.success)
                                        missionStore.promoteToActiveMission(vaultMissionId: mission.id)
                                        dismiss()
                                    } onDelete: {
                                        HapticsManager.shared.impact(.light)
                                        missionStore.deleteFromVault(id: mission.id)
                                    }
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
    }

    private func depositMission() {
        guard !newVaultTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        HapticsManager.shared.notification(.success)
        missionStore.addToVault(
            title: newVaultTitle,
            targetDate: newVaultTargetDate
        )
        newVaultTitle = ""
    }
}

// ── Vault Card ──
private struct VaultCard: View {
    let mission: Mission
    let theme: ThemeTokens
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
                        Text("ACTIVATE")
                        Image(systemName: "arrow.up.right")
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
