import SwiftUI

/// Reactive events that trigger atmospheric illumination on the Keystone Card
public enum KeystoneEvent: Equatable {
    case none
    case taskCompleted
    case taskAdded
    case taskDeleted
}

/// A luxury continuous-corner rounded card housing the Mission Title, Countdown, and Dot Grid Matrix.
/// Features an organic, living ambient aurora in the background and reactive lighting ripples on task events.
public struct KeystoneCardView<Content: View>: View {
    @ViewBuilder public let content: () -> Content
    public let event: KeystoneEvent
    public let isCompleting: Bool

    @Environment(\.theme) private var theme

    // Ambient Living Aurora State
    @State private var auroraPulse: Bool = false
    @State private var auroraRotation: Double = 0.0

    // Reactive Illumination Overlays
    @State private var pulseOpacity: Double = 0.0
    @State private var pulseColor: Color = .clear
    @State private var rimGlowOpacity: Double = 0.0
    @State private var rimGlowColor: Color = .clear
    @State private var scaleBreath: CGFloat = 1.0

    // Emerald Green for Accomplishment
    private let successEmerald = Color(red: 0.32, green: 0.72, blue: 0.53)

    public init(
        event: KeystoneEvent = .none,
        isCompleting: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.event = event
        self.isCompleting = isCompleting
        self.content = content
    }

    public var body: some View {
        ZStack {
            // ── Base Glassmorphic Surface ──
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.surface.opacity(0.35))

            // ── Ambient Living Aurora (Organic Drift Behind Content) ──
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // Orb 1: Warm Accent Aura (Drifting top-right to center)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.accent.opacity(auroraPulse ? 0.12 : 0.05),
                                    theme.accent.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: w * 0.6
                            )
                        )
                        .frame(width: w * 0.9, height: h * 0.9)
                        .position(
                            x: auroraPulse ? w * 0.70 : w * 0.35,
                            y: auroraPulse ? h * 0.30 : h * 0.65
                        )
                        .blur(radius: 35)

                    // Orb 2: Deep Charcoal / Subtle Secondary Radiance
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.textTertiary.opacity(auroraPulse ? 0.08 : 0.03),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: w * 0.5
                            )
                        )
                        .frame(width: w * 0.75, height: h * 0.75)
                        .position(
                            x: auroraPulse ? w * 0.30 : w * 0.65,
                            y: auroraPulse ? h * 0.70 : h * 0.35
                        )
                        .blur(radius: 30)
                }
            }
            .allowsHitTesting(false)

            // ── Reactive Event Illumination Wash (Task Complete, Added, Deleted) ──
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            pulseColor.opacity(pulseOpacity),
                            pulseColor.opacity(pulseOpacity * 0.3),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .allowsHitTesting(false)

            // ── Mission Victory Radiant Bloom ──
            if isCompleting {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.accent.opacity(0.22))
                    .blur(radius: 20)
                    .transition(.opacity)
            }

            // ── Embedded Mission Content (Title + Countdown + Dot Matrix) ──
            VStack(spacing: 4) {
                content()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)

            // ── Subtle Glass Rim Stroke (Catches Light on Events) ──
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    rimGlowOpacity > 0
                        ? rimGlowColor.opacity(rimGlowOpacity)
                        : theme.border.opacity(0.4),
                    lineWidth: rimGlowOpacity > 0 ? 1.2 : 0.8
                )
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .scaleEffect(scaleBreath)
        .shadow(
            color: isCompleting
                ? theme.accent.opacity(0.4)
                : (rimGlowOpacity > 0 ? rimGlowColor.opacity(0.2) : theme.accent.opacity(0.04)),
            radius: isCompleting ? 24 : (rimGlowOpacity > 0 ? 16 : 10),
            x: 0,
            y: 4
        )
        .onAppear {
            // Start the infinite living aurora drift
            withAnimation(.easeInOut(duration: 6.5).repeatForever(autoreverses: true)) {
                auroraPulse = true
            }
        }
        .onChange(of: event) { _, newEvent in
            handleEvent(newEvent)
        }
    }

    private func handleEvent(_ event: KeystoneEvent) {
        switch event {
        case .taskCompleted:
            // Emerald-Gold Wave Wash + Rim Flare
            withAnimation(.easeOut(duration: 0.25)) {
                pulseColor = successEmerald
                pulseOpacity = 0.20
                rimGlowColor = successEmerald
                rimGlowOpacity = 0.70
                scaleBreath = 1.008
            }
            // Decay back to ambient
            withAnimation(.easeOut(duration: 1.1).delay(0.25)) {
                pulseOpacity = 0.0
                rimGlowOpacity = 0.0
                scaleBreath = 1.0
            }

        case .taskAdded:
            // Spring expansion breath + Warm Accent Rim Flare
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                scaleBreath = 1.018
                rimGlowColor = theme.accent
                rimGlowOpacity = 0.55
                pulseColor = theme.accent
                pulseOpacity = 0.12
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                scaleBreath = 1.0
                rimGlowOpacity = 0.0
                pulseOpacity = 0.0
            }

        case .taskDeleted:
            // Subtle cool-slate desaturation breath
            withAnimation(.easeOut(duration: 0.2)) {
                pulseColor = theme.textTertiary
                pulseOpacity = 0.15
                rimGlowColor = theme.textSecondary
                rimGlowOpacity = 0.35
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                pulseOpacity = 0.0
                rimGlowOpacity = 0.0
            }

        case .none:
            break
        }
    }
}
