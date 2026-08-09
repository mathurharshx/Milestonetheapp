import SwiftUI

public struct MissionCelebrationSheet: View {
    public let mission: Mission
    public let quote: Quote?
    public let onArchive: () -> Void
    public let onNewMission: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimation: Bool = false

    public init(
        mission: Mission,
        quote: Quote?,
        onArchive: @escaping () -> Void,
        onNewMission: @escaping () -> Void
    ) {
        self.mission = mission
        self.quote = quote
        self.onArchive = onArchive
        self.onNewMission = onNewMission
    }

    private var totalDays: Int {
        DateCalculations.getTotalDays(createdAt: mission.createdAt, targetDate: mission.targetDate)
    }

    public var body: some View {
        ZStack {
            // Background Frosted Surface
            theme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(theme.textTertiary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 28) {
                        // ── Clean Minimalist Award Seal (No Blur/Shadows) ──
                        VStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 64, weight: .semibold))
                                .foregroundStyle(theme.accent)
                                .scaleEffect(appearAnimation ? 1.0 : 0.3)
                        }
                        .frame(height: 90)

                        // ── Milestone Title ──
                        VStack(spacing: 8) {
                            Text("MISSION ACCOMPLISHED")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(3.5)
                                .foregroundStyle(theme.accent)

                            Text(mission.title)
                                .font(.system(size: 26, weight: .bold))
                                .tracking(-0.5)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(theme.textPrimary)
                                .padding(.horizontal, 16)
                        }

                        // ── Apple-Style Stat Chips ──
                        HStack(spacing: 12) {
                            // Chip 1: Days
                            StatChip(
                                icon: "calendar.badge.checkmark",
                                value: "\(totalDays)d Goal",
                                label: "Target Met"
                            )

                            // Chip 2: Tasks Done
                            let doneCount = mission.todos.filter { $0.done }.count
                            let totalCount = mission.todos.count
                            StatChip(
                                icon: "checklist",
                                value: totalCount > 0 ? "\(doneCount)/\(totalCount)" : "100%",
                                label: "Checklist"
                            )
                        }
                        .padding(.horizontal, 8)

                        // ── Inspirational Quote Card ──
                        if let quote = quote {
                            VStack(spacing: 12) {
                                Text("\"\(quote.text)\"")
                                    .font(.system(size: 16, weight: .regular, design: .serif))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .foregroundStyle(theme.textPrimary)

                                Text("— \(quote.author)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(theme.textTertiary)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.background.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(theme.border, lineWidth: 1)
                                    )
                            )
                        }

                        // ── Action Buttons ──
                        VStack(spacing: 12) {
                            // Primary: View in Archive
                            Button {
                                HapticsManager.shared.impact(.medium)
                                dismiss()
                                onArchive()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "archivebox.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("VIEW IN ARCHIVE")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(2)
                                }
                                .foregroundStyle(theme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(theme.accent)
                                )
                            }

                            // Secondary: Start New Mission
                            Button {
                                HapticsManager.shared.impact(.light)
                                dismiss()
                                onNewMission()
                            } label: {
                                Text("START NEW MISSION")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(2)
                                    .foregroundStyle(theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .presentationDetents([.fraction(0.82), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appearAnimation = true
            }
        }
    }
}

// ── Stat Chip Component ──
private struct StatChip: View {
    let icon: String
    let value: String
    let label: String
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.accent)

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(theme.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.background.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.border, lineWidth: 1)
                )
        )
    }
}
