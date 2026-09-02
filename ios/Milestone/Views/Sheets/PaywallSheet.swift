import SwiftUI
import StoreKit

public struct PaywallSheet: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    public enum BillingPeriod {
        case annual
        case monthly
        case lifetime
    }

    @State private var selectedPeriod: BillingPeriod = .annual
    @State private var isPurchasing: Bool = false
    @State private var alertMessage: String?
    @State private var showAlert: Bool = false

    public init() {}

    private var annualProduct: Product? {
        subscriptionStore.products.first(where: { $0.id.contains("annual") })
    }

    private var monthlyProduct: Product? {
        subscriptionStore.products.first(where: { $0.id.contains("monthly") })
    }

    private var lifetimeProduct: Product? {
        subscriptionStore.products.first(where: { $0.id.contains("lifetime") })
    }

    public var body: some View {
        ZStack {
            // Obsidian Backdrop
            theme.background.ignoresSafeArea()

            // Ambient Gold Rim Flare
            VStack {
                Circle()
                    .fill(theme.accent.opacity(0.14))
                    .frame(width: 260, height: 260)
                    .blur(radius: 50)
                    .offset(y: -70)
                Spacer()
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top Dismiss Bar
                HStack {
                    Spacer()
                    Button {
                        HapticsManager.shared.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(theme.textTertiary.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Scrollable container (fits 100% on standard screens, scrolls gracefully on smaller displays)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // ── 1. Hero Title ──
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(theme.accent)

                                Text("MILESTONE PREMIUM")
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(3)
                                    .foregroundStyle(theme.accent)
                            }

                            Text("Master your focus.")
                                .font(.system(size: 24, weight: .bold))
                                .tracking(-0.5)
                                .foregroundStyle(theme.textPrimary)
                        }

                        // ── 2. X.com Style Segmented Billing Switcher ──
                        HStack(spacing: 0) {
                            // Annual Toggle
                            Button {
                                HapticsManager.shared.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedPeriod = .annual
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Annual")
                                        .font(.system(size: 13, weight: .bold))

                                    Text("SAVE 37%")
                                        .font(.system(size: 9, weight: .black))
                                        .tracking(1)
                                        .foregroundStyle(selectedPeriod == .annual ? theme.background : theme.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(selectedPeriod == .annual ? theme.accent : theme.accentDim)
                                        )
                                }
                                .foregroundStyle(selectedPeriod == .annual ? theme.textPrimary : theme.textTertiary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPeriod == .annual ? theme.surfaceLight : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)

                            // Monthly Toggle
                            Button {
                                HapticsManager.shared.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedPeriod = .monthly
                                }
                            } label: {
                                Text("Monthly")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(selectedPeriod == .monthly ? theme.textPrimary : theme.textTertiary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedPeriod == .monthly ? theme.surfaceLight : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.surface.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.border.opacity(0.4), lineWidth: 1)
                        )

                        // ── 3. Bento Grid of Superpowers ──
                        VStack(spacing: 8) {
                            // Bento 1: Wide Hero (ADHD Soundscapes)
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.accent.opacity(0.15))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "waveform")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(theme.accent)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("ADHD Focus Soundscapes")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(theme.textPrimary)

                                        Text("40Hz GAMMA")
                                            .font(.system(size: 8, weight: .heavy))
                                            .tracking(1)
                                            .foregroundStyle(theme.accent)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(theme.accentDim))
                                    }

                                    Text("Procedural brown noise & gamma binaural beats to silence mental friction.")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(theme.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.surface.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.accent.opacity(0.35), lineWidth: 1)
                            )

                            // Bento 2 & 3: Two-Column Row (The Vault + Dual-Track)
                            HStack(spacing: 8) {
                                // Vault Box
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "archivebox.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(theme.accent)
                                        Spacer()
                                        Text("COLD STORAGE")
                                            .font(.system(size: 8, weight: .heavy))
                                            .foregroundStyle(theme.textTertiary)
                                    }

                                    Text("The Vault")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("Park future goals safely so you don't dilute today's mission.")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(theme.textSecondary)
                                        .lineLimit(2)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(theme.surface.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.border.opacity(0.3), lineWidth: 1)
                                )

                                // Dual Track Box
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "circle.grid.2x1.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color(red: 0.32, green: 0.72, blue: 0.53))
                                        Spacer()
                                        Text("BALANCED")
                                            .font(.system(size: 8, weight: .heavy))
                                            .foregroundStyle(theme.textTertiary)
                                    }

                                    Text("Dual Pillars")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("Lock 1 Work Mountain and 1 Personal Mountain simultaneously.")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(theme.textSecondary)
                                        .lineLimit(2)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(theme.surface.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.border.opacity(0.3), lineWidth: 1)
                                )
                            }

                            // Bento 4: Wide Bottom Card (Velocity & Streak Analytics)
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.surfaceLight.opacity(0.7))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(theme.textPrimary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Deep Velocity & Pacing Reports")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("Detect timeline drift early and track consecutive sprint streaks.")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(theme.textSecondary)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.surface.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.border.opacity(0.3), lineWidth: 1)
                            )
                        }

                        // ── 4. Dynamic Pricing Display ──
                        VStack(spacing: 4) {
                            if selectedPeriod == .annual {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(annualProduct?.displayPrice ?? "$29.99")
                                        .font(.system(size: 26, weight: .heavy))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("/ year")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(theme.textSecondary)

                                    Text("($2.49/mo)")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundStyle(theme.accent)
                                }

                                Text("Includes 7 days free. Cancel anytime before trial ends.")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(theme.textTertiary)
                            } else if selectedPeriod == .monthly {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(monthlyProduct?.displayPrice ?? "$3.99")
                                        .font(.system(size: 26, weight: .heavy))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("/ month")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(theme.textSecondary)
                                }

                                Text("Billed monthly. Cancel anytime in App Store settings.")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(theme.textTertiary)
                            } else {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(lifetimeProduct?.displayPrice ?? "$49.99")
                                        .font(.system(size: 26, weight: .heavy))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("one-time")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(theme.accent)
                                }

                                Text("Never pay again. All future updates included forever.")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(theme.textTertiary)
                            }

                            // Secondary Lifetime Option Switch
                            Button {
                                HapticsManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedPeriod = selectedPeriod == .lifetime ? .annual : .lifetime
                                }
                            } label: {
                                Text(selectedPeriod == .lifetime ? "Switch back to Annual ($29.99/yr)" : "Prefer lifetime? Get Lifetime Access for $49.99")
                                    .font(.system(size: 11, weight: .medium))
                                    .underline()
                                    .foregroundStyle(theme.textTertiary.opacity(0.8))
                                    .padding(.top, 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 20)
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
                                Image(systemName: selectedPeriod == .annual ? "sparkles" : "arrow.right")
                                    .font(.system(size: 13, weight: .bold))

                                Text(ctaTitle)
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(2)
                            }
                        }
                        .foregroundStyle(theme.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(theme.accent)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing)

                    // Apple Review Guideline Links
                    HStack(spacing: 14) {
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
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(theme.textTertiary.opacity(0.8))
                    .padding(.top, 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .background(
                    theme.background
                        .shadow(color: Color.black.opacity(0.35), radius: 10, y: -4)
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

    private var ctaTitle: String {
        switch selectedPeriod {
        case .annual: return "START 7-DAY FREE TRIAL"
        case .monthly: return "UPGRADE TO PREMIUM"
        case .lifetime: return "GET LIFETIME ACCESS"
        }
    }

    private func handlePurchase() {
        HapticsManager.shared.impact(.medium)
        isPurchasing = true

        Task {
            defer { isPurchasing = false }

            let targetTierID: String
            switch selectedPeriod {
            case .annual: targetTierID = SubscriptionTier.annual.rawValue
            case .monthly: targetTierID = SubscriptionTier.monthly.rawValue
            case .lifetime: targetTierID = SubscriptionTier.lifetime.rawValue
            }

            if let product = subscriptionStore.products.first(where: { $0.id == targetTierID }) {
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
                // In simulator debug mode, simulate instant Pro activation
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
