import SwiftUI
import StoreKit

public struct PaywallSheet: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTier: SubscriptionTier = .annual
    @State private var isPurchasing: Bool = false
    @State private var alertMessage: String?
    @State private var showAlert: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            // Obsidian Canvas
            theme.background.ignoresSafeArea()

            // Ambient Glow
            VStack {
                Circle()
                    .fill(theme.accent.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(y: -100)
                Spacer()
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Spacer()
                    Button {
                        HapticsManager.shared.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(theme.textTertiary.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // ── 1. Hero Header ──
                        VStack(spacing: 12) {
                            // Crown / Seal Icon
                            ZStack {
                                Circle()
                                    .fill(theme.accent.opacity(0.15))
                                    .frame(width: 64, height: 64)

                                Image(systemName: "crown.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(theme.accent)
                            }

                            Text("MILESTONE SOVEREIGN")
                                .font(.system(size: 11, weight: .black))
                                .tracking(4)
                                .foregroundStyle(theme.accent)

                            Text("Master your focus.\nConquer every mountain.")
                                .font(.system(size: 24, weight: .bold))
                                .tracking(-0.5)
                                .foregroundStyle(theme.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        // ── 2. Feature Cards ──
                        VStack(spacing: 12) {
                            FeatureRow(
                                icon: "waveform",
                                title: "ADHD Focus Soundscapes",
                                description: "40Hz gamma focus frequencies and brown noise to quiet mental noise.",
                                theme: theme
                            )

                            FeatureRow(
                                icon: "archivebox.circle",
                                title: "The Mission Vault",
                                description: "Park future ideas in cold storage so your mind stays locked on one goal.",
                                theme: theme
                            )

                            FeatureRow(
                                icon: "circle.grid.2x1.fill",
                                title: "Dual-Track Pillars",
                                description: "Balance 1 Work Mission and 1 Personal Mission simultaneously.",
                                theme: theme
                            )

                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Velocity Analytics",
                                description: "Detailed focus velocity reports, sprint consistency, and pacing charts.",
                                theme: theme
                            )
                        }
                        .padding(.horizontal, 4)

                        // ── 3. Plan Options ──
                        VStack(spacing: 10) {
                            // Annual (Best Value)
                            PlanOptionCard(
                                tier: .annual,
                                title: "Annual Sovereign",
                                price: subscriptionStore.products.first(where: { $0.id.contains("annual") })?.displayPrice ?? "$29.99/yr",
                                subprice: "$2.49/mo • 7-day free trial",
                                badge: "SAVE 37%",
                                isSelected: selectedTier == .annual,
                                theme: theme
                            ) {
                                selectedTier = .annual
                            }

                            // Monthly
                            PlanOptionCard(
                                tier: .monthly,
                                title: "Monthly",
                                price: subscriptionStore.products.first(where: { $0.id.contains("monthly") })?.displayPrice ?? "$3.99/mo",
                                subprice: "Billed monthly. Cancel anytime.",
                                badge: nil,
                                isSelected: selectedTier == .monthly,
                                theme: theme
                            ) {
                                selectedTier = .monthly
                            }

                            // Lifetime
                            PlanOptionCard(
                                tier: .lifetime,
                                title: "Lifetime Access",
                                price: subscriptionStore.products.first(where: { $0.id.contains("lifetime") })?.displayPrice ?? "$49.99",
                                subprice: "Pay once. Never pay again.",
                                badge: "LIFETIME",
                                isSelected: selectedTier == .lifetime,
                                theme: theme
                            ) {
                                selectedTier = .lifetime
                            }
                        }

                        // ── 4. Legal / Restore ──
                        HStack(spacing: 16) {
                            Button("Restore Purchases") {
                                Task {
                                    await subscriptionStore.restorePurchases()
                                    if subscriptionStore.isProUser {
                                        dismiss()
                                    }
                                }
                            }

                            Text("•")

                            Link("Terms of Use", destination: URL(string: "https://milestone.app/terms")!)

                            Text("•")

                            Link("Privacy Policy", destination: URL(string: "https://milestone.app/privacy")!)
                        }
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(theme.textTertiary)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                }

                // ── 5. Pinned Bottom CTA ──
                VStack(spacing: 8) {
                    Button {
                        handlePurchase()
                    } label: {
                        HStack(spacing: 8) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(theme.background)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .bold))

                                Text(selectedTier == .annual ? "START 7-DAY FREE TRIAL" : "CONTINUE")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(2.5)
                            }
                        }
                        .foregroundStyle(theme.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.accent)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing)

                    Text(selectedTier == .annual ? "Free for 7 days, then $29.99/year. Cancel anytime." : "No commitment. Cancel anytime in App Store settings.")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .background(
                    theme.background
                        .shadow(color: Color.black.opacity(0.3), radius: 10, y: -4)
                )
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Notice"),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func handlePurchase() {
        HapticsManager.shared.impact(.medium)
        isPurchasing = true

        Task {
            defer { isPurchasing = false }

            if let product = subscriptionStore.products.first(where: { $0.id == selectedTier.rawValue }) {
                do {
                    let success = try await subscriptionStore.purchase(product)
                    if success {
                        dismiss()
                    }
                } catch {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            } else {
#if DEBUG
                // In simulator debug mode, simulate instant purchase
                subscriptionStore.toggleDebugPro()
                dismiss()
#else
                alertMessage = "Unable to connect to the App Store. Please try again."
                showAlert = true
#endif
            }
        }
    }
}

// ── Feature Row ──
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let theme: ThemeTokens

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.surfaceLight.opacity(0.7))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.textPrimary)

                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.surface.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.border.opacity(0.4), lineWidth: 1)
        )
    }
}

// ── Plan Option Card ──
private struct PlanOptionCard: View {
    let tier: SubscriptionTier
    let title: String
    let price: String
    let subprice: String
    let badge: String?
    let isSelected: Bool
    let theme: ThemeTokens
    let onSelect: () -> Void

    var body: some View {
        Button {
            HapticsManager.shared.selection()
            onSelect()
        } label: {
            HStack(spacing: 14) {
                // Radio Circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? theme.accent : theme.textTertiary, lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.textPrimary)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .black))
                                .tracking(1)
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(theme.accentDim))
                        }
                    }

                    Text(subprice)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(theme.textTertiary)
                }

                Spacer()

                Text(price)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? theme.accent : theme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? theme.surfaceLight.opacity(0.8) : theme.surface.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.accent.opacity(0.8) : theme.border.opacity(0.4), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
