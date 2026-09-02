import SwiftUI
import StoreKit

public struct PaywallSheet: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Namespace private var tabNamespace

    public enum BillingPeriod: String, CaseIterable, Identifiable {
        case monthly
        case annual
        case lifetime

        public var id: String { rawValue }
    }

    public enum PremiumFeature: String, Identifiable {
        case soundscapes
        case vault
        case dualPillars
        case velocity

        public var id: String { rawValue }
    }

    @State private var selectedPeriod: BillingPeriod = .annual
    @State private var expandedFeature: PremiumFeature? = nil
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
                    .frame(width: 280, height: 280)
                    .blur(radius: 50)
                    .offset(y: -80)
                Spacer()
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // ── Top Navigation Bar ──
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.accent)

                        Text("MILESTONE PREMIUM")
                            .font(.system(size: 11, weight: .black))
                            .tracking(3)
                            .foregroundStyle(theme.accent)
                    }

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
                .padding(.top, 16)
                .padding(.bottom, 6)

                // ── Scrollable Content Area ──
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Title
                        Text("Master your focus.")
                            .font(.system(size: 25, weight: .bold))
                            .tracking(-0.5)
                            .foregroundStyle(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.top, 2)

                        // ── 1. Underline Tab Switcher: MONTHLY (1st) & ANNUAL (2nd) ──
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                // Monthly Tab (First)
                                tabButton(
                                    period: .monthly,
                                    title: "MONTHLY",
                                    badge: nil
                                )

                                // Annual Tab (Second)
                                tabButton(
                                    period: .annual,
                                    title: "ANNUAL",
                                    badge: "SAVE 37%"
                                )
                            }

                            // Full-width subtle baseline
                            Rectangle()
                                .fill(theme.border.opacity(0.35))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 4)

                        // ── 2. Interactive Bento Grid of Features ──
                        VStack(spacing: 10) {
                            // Bento 1: ADHD Focus Soundscapes (Wide Hero)
                            bentoCard(
                                feature: .soundscapes,
                                icon: "waveform",
                                iconColor: theme.accent,
                                title: "ADHD Focus Soundscapes",
                                badge: "40Hz GAMMA",
                                badgeColor: theme.accent,
                                summary: "Procedural brown noise & 40Hz gamma binaural frequencies to eliminate mental friction.",
                                detail: "Synthesizes real-time acoustic frequencies directly on-device with zero internet required. 40Hz gamma neural entrainment stimulates the prefrontal cortex for sustained focus, while continuous brown noise quiets intrusive ADHD racing thoughts."
                            )

                            // Bento 2 & 3: Two-Column Row (The Vault + Dual Pillars)
                            HStack(alignment: .top, spacing: 10) {
                                // The Vault
                                bentoCard(
                                    feature: .vault,
                                    icon: "archivebox.fill",
                                    iconColor: theme.accent,
                                    title: "The Vault",
                                    badge: "COLD STORAGE",
                                    badgeColor: theme.accent,
                                    summary: "Park future ideas safely in cold storage so today's mission stays protected.",
                                    detail: "Had a brilliant new project idea while working? Don't break your momentum. Deposit it into The Vault in 1 tap. Keep your dopamine locked on your current single mission until completed, then promote any queued mission with one tap."
                                )

                                // Dual Pillars
                                bentoCard(
                                    feature: .dualPillars,
                                    icon: "circle.grid.2x1.fill",
                                    iconColor: Color(red: 0.32, green: 0.72, blue: 0.53),
                                    title: "Dual Pillars",
                                    badge: "BALANCED",
                                    badgeColor: Color(red: 0.32, green: 0.72, blue: 0.53),
                                    summary: "Run 1 Work Mission and 1 Personal Mission simultaneously.",
                                    detail: "The only exception to the single-goal rule. Dual Pillars allows ambitious creators to balance one professional mission and one personal habit side-by-side without context switching or burnout."
                                )
                            }

                            // Bento 4: Deep Velocity & Pacing Reports (Wide Bottom)
                            bentoCard(
                                feature: .velocity,
                                icon: "chart.line.uptrend.xyaxis",
                                iconColor: theme.accent,
                                title: "Deep Velocity & Pacing Reports",
                                badge: "DEEP STATS",
                                badgeColor: theme.textTertiary,
                                summary: "Detect timeline drift early and track consecutive sprint completion streaks.",
                                detail: "Real-time mathematical forecasting based on your actual sprint velocity. Automatically calculates timeline drift alerts before deadlines slip and generates exportable sprint reports."
                            )
                        }
                        .padding(.horizontal, 2)

                        // ── 3. Dynamic Pricing Display ──
                        VStack(spacing: 4) {
                            if selectedPeriod == .monthly {
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
                            } else if selectedPeriod == .annual {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(annualProduct?.displayPrice ?? "$29.99")
                                        .font(.system(size: 26, weight: .heavy))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("/ year")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(theme.textSecondary)

                                    Text("($2.49/mo)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(theme.accent)
                                }

                                Text("Includes 7 days free. Cancel anytime in App Store before trial ends.")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(theme.textTertiary)
                            } else {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(lifetimeProduct?.displayPrice ?? "$49.99")
                                        .font(.system(size: 26, weight: .heavy))
                                        .foregroundStyle(theme.textPrimary)

                                    Text("one-time payment")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(theme.accent)
                                }

                                Text("Pay once. Never pay again. All current and future updates included forever.")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(theme.textTertiary)
                            }
                        }
                        .padding(.vertical, 4)

                        // ── 4. Highlighted Lifetime Pass Look Below ──
                        Button {
                            HapticsManager.shared.selection()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                if selectedPeriod == .lifetime {
                                    selectedPeriod = .annual
                                } else {
                                    selectedPeriod = .lifetime
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(theme.accent)

                                Text("Lifetime Pass:")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(theme.textPrimary)

                                Text("Pay $49.99 once for forever access")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(theme.textSecondary)

                                Spacer()

                                if selectedPeriod == .lifetime {
                                    Text("SELECTED")
                                        .font(.system(size: 9, weight: .black))
                                        .tracking(1)
                                        .foregroundStyle(theme.background)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(theme.accent))
                                } else {
                                    Text("SELECT")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(0.5)
                                        .foregroundStyle(theme.accent)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPeriod == .lifetime ? theme.accent.opacity(0.12) : theme.surfaceLight.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedPeriod == .lifetime ? theme.accent : theme.border.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 12)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // ── 5. App Store Review Compliant Grounded Bottom Bar ──
                VStack(spacing: 10) {
                    Button {
                        handlePurchase()
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(theme.background)
                            } else {
                                Text(ctaTitle)
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(theme.background)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(theme.accent)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing)

                    // App Store Compliant Legal & Restore Links
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

                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)

                        Text("•")

                        Link("Privacy Policy", destination: URL(string: "https://github.com/mathurharshx/Milestonetheapp/blob/main/PRIVACY.md")!)
                    }
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(theme.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(
                    theme.background
                        .shadow(color: Color.black.opacity(0.5), radius: 12, y: -4)
                        .ignoresSafeArea(.all, edges: .bottom)
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

    // ── Helper: Underline Tab Button ──
    @ViewBuilder
    private func tabButton(period: BillingPeriod, title: String, badge: String?) -> some View {
        let isSelected = selectedPeriod == period

        Button {
            HapticsManager.shared.selection()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                selectedPeriod = period
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: isSelected ? .black : .bold))
                        .tracking(1)
                        .foregroundStyle(isSelected ? theme.accent : theme.textTertiary)

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(0.5)
                            .foregroundStyle(isSelected ? theme.background : theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(isSelected ? theme.accent : theme.accentDim)
                            )
                    }
                }
                .padding(.horizontal, 8)

                // Active Sliding Underline Indicator
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(theme.accent)
                            .frame(height: 2.5)
                            .matchedGeometryEffect(id: "activeUnderline", in: tabNamespace)
                    } else {
                        Color.clear.frame(height: 2.5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // ── Helper: Expandable Bento Grid Card ──
    @ViewBuilder
    private func bentoCard(
        feature: PremiumFeature,
        icon: String,
        iconColor: Color,
        title: String,
        badge: String,
        badgeColor: Color,
        summary: String,
        detail: String
    ) -> some View {
        let isExpanded = expandedFeature == feature

        Button {
            HapticsManager.shared.impact(.light)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if expandedFeature == feature {
                    expandedFeature = nil
                } else {
                    expandedFeature = feature
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(iconColor)

                    Text(badge)
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(badgeColor)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.textTertiary.opacity(0.8))
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(theme.textPrimary)

                // Full summary text (no truncation)
                Text(summary)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Expanded Deep-Dive Explanation
                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        Divider()
                            .overlay(theme.border.opacity(0.4))
                            .padding(.vertical, 2)

                        Text(detail)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(theme.textPrimary.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isExpanded ? theme.surfaceLight.opacity(0.8) : theme.surface.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isExpanded ? theme.accent : theme.border.opacity(0.3), lineWidth: isExpanded ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var ctaTitle: String {
        switch selectedPeriod {
        case .monthly: return "UPGRADE TO PREMIUM"
        case .annual: return "START 7-DAY FREE TRIAL"
        case .lifetime: return "GET LIFETIME ACCESS — $49.99"
        }
    }

    private func handlePurchase() {
        HapticsManager.shared.impact(.medium)
        isPurchasing = true

        Task {
            defer { isPurchasing = false }

            let targetTierID: String
            switch selectedPeriod {
            case .monthly: targetTierID = SubscriptionTier.monthly.rawValue
            case .annual: targetTierID = SubscriptionTier.annual.rawValue
            case .lifetime: targetTierID = SubscriptionTier.lifetime.rawValue
            }

            if let product = subscriptionStore.products.first(where: { $0.id == targetTierID }) {
                do {
                    let success = try await subscriptionStore.purchase(product)
                    if success {
                        dismiss()
                    }
                } catch {
#if DEBUG
                    print("StoreKit purchase note in DEBUG: \(error.localizedDescription) - activating Pro for testing")
                    subscriptionStore.activatePro()
                    dismiss()
#else
                    alertMessage = error.localizedDescription
                    showAlert = true
#endif
                }
            } else {
                // If products are not available in current environment (e.g. simulator sandbox or before store approval)
#if DEBUG
                print("DEBUG: Products empty - activating Pro instantly")
                subscriptionStore.activatePro()
                dismiss()
#else
                alertMessage = "Connecting to the App Store. Please try again."
                showAlert = true
#endif
            }
        }
    }
}
