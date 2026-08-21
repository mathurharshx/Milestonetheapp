import SwiftUI
import UIKit

public struct MissionCelebrationSheet: View {
    public let mission: Mission
    public let quote: Quote?
    public let onArchive: () -> Void
    public let onNewMission: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var sealAnimation: Bool = false
    @State private var contentAnimation: Bool = false
    @State private var matrixWaveAnimation: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var exportedImage: UIImage? = nil

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
            // ── 1. Obsidian Background Canvas ──
            theme.background
                .ignoresSafeArea()

            // ── 2. Ambient Matrix Illumination Wave ──
            VStack {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 12), spacing: 10) {
                    ForEach(0..<96, id: \.self) { idx in
                        Circle()
                            .fill(matrixWaveAnimation ? theme.accent.opacity(Double.random(in: 0.15...0.45)) : theme.border.opacity(0.15))
                            .frame(width: 4, height: 4)
                            .scaleEffect(matrixWaveAnimation ? 1.2 : 0.8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                Spacer()
            }
            .allowsHitTesting(false)
            .opacity(0.6)

            // ── 3. Monolith Ceremony Content ──
            VStack(spacing: 0) {
                // Top Close Bar
                HStack {
                    Spacer()
                    Button {
                        HapticsManager.shared.impact(.light)
                        dismiss()
                        onArchive()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(theme.textTertiary.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // ── 4. Descending 3D Monolith Wax Seal ──
                        VStack(spacing: 16) {
                            ZStack {
                                // Outer Ambient Pulse Ring
                                Circle()
                                    .fill(theme.accent.opacity(0.12))
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(sealAnimation ? 1.15 : 0.85)

                                // Metallic Border
                                Circle()
                                    .stroke(
                                        AngularGradient(
                                            colors: [theme.accent, theme.textPrimary, theme.accent, theme.textTertiary],
                                            center: .center
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 96, height: 96)

                                // Inner Core
                                Circle()
                                    .fill(theme.surface)
                                    .frame(width: 90, height: 90)

                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundStyle(theme.accent)
                            }
                            .scaleEffect(sealAnimation ? 1.0 : 0.2)
                            .rotationEffect(.degrees(sealAnimation ? 0 : -30))
                            .shadow(color: theme.accent.opacity(0.3), radius: sealAnimation ? 20 : 0, x: 0, y: 8)

                            Text("✦ ACCOMPLISHED ✦")
                                .font(.system(size: 11, weight: .black))
                                .tracking(4)
                                .foregroundStyle(theme.accent)
                                .opacity(contentAnimation ? 1.0 : 0.0)
                        }
                        .padding(.top, 10)

                        // ── 5. Mission Title ──
                        VStack(spacing: 8) {
                            Text(mission.title)
                                .font(.system(size: 32, weight: .bold))
                                .tracking(-0.8)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(theme.textPrimary)
                                .padding(.horizontal, 16)

                            if let note = mission.note, !note.isEmpty {
                                Text(note)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(theme.textTertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .opacity(contentAnimation ? 1.0 : 0.0)
                        .offset(y: contentAnimation ? 0 : 20)

                        // ── 6. Stat Badges ──
                        HStack(spacing: 12) {
                            StatBadgeCard(
                                icon: "calendar.badge.checkmark",
                                value: "\(totalDays) Days",
                                label: "Target Achieved",
                                theme: theme
                            )

                            let doneCount = mission.todos.filter { $0.done }.count
                            let totalCount = mission.todos.count
                            StatBadgeCard(
                                icon: "checklist",
                                value: totalCount > 0 ? "\(doneCount)/\(totalCount)" : "100%",
                                label: "Checklist",
                                theme: theme
                            )
                        }
                        .opacity(contentAnimation ? 1.0 : 0.0)
                        .offset(y: contentAnimation ? 0 : 20)

                        // ── 7. Inspirational Quote ──
                        if let quote = quote {
                            VStack(spacing: 12) {
                                Text("\"\(quote.text)\"")
                                    .font(.system(size: 15, weight: .regular, design: .serif))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .foregroundStyle(theme.textPrimary)

                                Text("— \(quote.author)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(theme.textTertiary)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.surfaceLight.opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.border.opacity(0.6), lineWidth: 1)
                            )
                            .opacity(contentAnimation ? 1.0 : 0.0)
                            .offset(y: contentAnimation ? 0 : 20)
                        }

                        // ── 8. Certificate Actions ──
                        VStack(spacing: 14) {
                            // Primary: View in Archive
                            Button {
                                HapticsManager.shared.impact(.medium)
                                dismiss()
                                onArchive()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "archivebox.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("VIEW IN ARCHIVE")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(2.5)
                                }
                                .foregroundStyle(theme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(theme.accent)
                                )
                            }

                            // Secondary: Share Certificate
                            Button {
                                renderCertificateImage()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("SHARE CERTIFICATE")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(2)
                                }
                                .foregroundStyle(theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(theme.border, lineWidth: 1)
                                )
                            }

                            // Tertiary: Start New Mission
                            Button {
                                HapticsManager.shared.impact(.light)
                                dismiss()
                                onNewMission()
                            } label: {
                                Text("START NEW MISSION")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(2)
                                    .foregroundStyle(theme.textTertiary)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 36)
                        .opacity(contentAnimation ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = exportedImage {
                ActivityViewController(activityItems: [image])
            }
        }
        .onAppear {
            // 1. Spring Seal Drop
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                sealAnimation = true
            }

            // 2. Content Fade Up
            withAnimation(.easeOut(duration: 0.45).delay(0.2)) {
                contentAnimation = true
            }

            // 3. Matrix Illumination Wave
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                matrixWaveAnimation = true
            }
        }
    }

    @MainActor
    private func renderCertificateImage() {
        HapticsManager.shared.impact(.light)
        let certificateView = CertificateCardView(mission: mission, totalDays: totalDays, theme: theme)
        let renderer = ImageRenderer(content: certificateView)
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            self.exportedImage = image
            self.showShareSheet = true
        }
    }
}

// ── Stat Badge Card Component ──
private struct StatBadgeCard: View {
    let icon: String
    let value: String
    let label: String
    let theme: ThemeTokens

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.accent)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(theme.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceLight.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.border.opacity(0.6), lineWidth: 1)
        )
    }
}

// ── Exportable Certificate Image View (9:16 Story Format) ──
private struct CertificateCardView: View {
    let mission: Mission
    let totalDays: Int
    let theme: ThemeTokens

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(theme.accent, lineWidth: 2)
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(theme.accent)
            }

            VStack(spacing: 6) {
                Text("MILESTONE ACCOMPLISHED")
                    .font(.system(size: 10, weight: .black))
                    .tracking(3)
                    .foregroundStyle(theme.accent)

                Text(mission.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(totalDays) DAYS")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    Text("GOAL MET")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }

                Divider().frame(height: 24).overlay(theme.border)

                VStack(spacing: 2) {
                    Text("100% DONE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    Text("CHECKLIST")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(theme.surfaceLight)
            )

            Text("milestones.app")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(theme.textTertiary.opacity(0.6))
        }
        .padding(32)
        .frame(width: 320, height: 420)
        .background(theme.background)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.border, lineWidth: 1.5)
        )
    }
}

// ── UIActivityViewController Wrapper for Sharing Certificate Image ──
private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
