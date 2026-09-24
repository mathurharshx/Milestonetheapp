import SwiftUI

/// Reactive events that trigger atmospheric illumination on the Keystone Card
public enum KeystoneEvent: Equatable {
    case none
    case taskCompleted
    case taskAdded
    case taskDeleted
}

/// A luxury continuous-corner rounded card housing the Mission Title, Countdown, and Dot Grid Matrix.
/// Features an organic, living ambient aurora in the background, reactive lighting ripples on task events,
/// and smooth 3D spatial ascension to Vault upon mission victory.
public struct KeystoneCardView<Content: View>: View {
    @ViewBuilder public let content: () -> Content
    public let event: KeystoneEvent
    public let isCompleting: Bool
    public let isAscending: Bool
    public let missionCategory: MissionCategory

    @Environment(\.theme) private var theme

    // Ambient Living Aurora State
    @State private var auroraPulse: Bool = false

    // Reactive Illumination Overlays
    @State private var pulseOpacity: Double = 0.0
    @State private var pulseColor: Color = .clear
    @State private var rimGlowOpacity: Double = 0.0
    @State private var rimGlowColor: Color = .clear
    @State private var scaleBreath: CGFloat = 1.0

    // Emerald Green for Accomplishment & Personal Pillar
    private let successEmerald = AppColors.personalEmerald

    // Warm Celestial Amber for Task Removal / Decluttering
    private let removalAmber = Color(red: 0.90, green: 0.62, blue: 0.32)

    public init(
        event: KeystoneEvent = .none,
        isCompleting: Bool = false,
        isAscending: Bool = false,
        missionCategory: MissionCategory = .work,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.event = event
        self.isCompleting = isCompleting
        self.isAscending = isAscending
        self.missionCategory = missionCategory
        self.content = content
    }

    private var activeAccentColor: Color {
        missionCategory == .personal ? successEmerald : theme.accent
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
                                stops: [
                                    .init(color: activeAccentColor.opacity(isCompleting ? 0.25 : (auroraPulse ? 0.12 : 0.05)), location: 0.0),
                                    .init(color: activeAccentColor.opacity(isCompleting ? 0.08 : (auroraPulse ? 0.04 : 0.01)), location: 0.5),
                                    .init(color: Color.clear, location: 0.95)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: max(w, h) * 0.55
                            )
                        )
                        .frame(width: w * 0.9, height: h * 0.9)
                        .position(
                            x: auroraPulse ? w * 0.70 : w * 0.35,
                            y: auroraPulse ? h * 0.30 : h * 0.65
                        )

                    // Orb 2: Deep Charcoal / Subtle Secondary Radiance
                    Circle()
                        .fill(
                            RadialGradient(
                                stops: [
                                    .init(color: theme.textTertiary.opacity(auroraPulse ? 0.08 : 0.03), location: 0.0),
                                    .init(color: Color.clear, location: 0.90)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: max(w, h) * 0.45
                            )
                        )
                        .frame(width: w * 0.75, height: h * 0.75)
                        .position(
                            x: auroraPulse ? w * 0.30 : w * 0.65,
                            y: auroraPulse ? h * 0.70 : h * 0.35
                        )
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

            // ── Mission Victory Radiant Bloom & Elevation Flare (Covers full card proportionally) ──
            if isCompleting {
                GeometryReader { geo in
                    let maxDim = max(geo.size.width, geo.size.height)
                    RadialGradient(
                        colors: [
                            activeAccentColor.opacity(0.24),
                            activeAccentColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: maxDim * 0.75
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .transition(.opacity)
            }

            // ── Embedded Mission Content (Title + Countdown + Dot Matrix) ──
            VStack(spacing: 4) {
                content()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)

            // ── Continuous Glass Rim Stroke (Unbroken on all 4 sides: Top, Bottom, Left, Right) ──
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    isCompleting
                        ? activeAccentColor.opacity(isAscending ? 0.95 : 0.80)
                        : (rimGlowOpacity > 0
                            ? rimGlowColor.opacity(rimGlowOpacity)
                            : theme.border.opacity(0.4)),
                    lineWidth: isCompleting ? (isAscending ? 2.2 : 1.8) : (rimGlowOpacity > 0 ? 1.2 : 0.8)
                )
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .scaleEffect(isAscending ? 0.88 : (isCompleting ? 1.025 : scaleBreath))
        .offset(y: isAscending ? -32 : (isCompleting ? -8 : 0))
        .opacity(isAscending ? 0.65 : 1.0)
        .rotation3DEffect(
            .degrees(isCompleting ? (isAscending ? -3.0 : -1.5) : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.2
        )
        .shadow(
            color: isCompleting
                ? activeAccentColor.opacity(isAscending ? 0.50 : 0.35)
                : (rimGlowOpacity > 0 ? rimGlowColor.opacity(0.2) : theme.accent.opacity(0.04)),
            radius: isCompleting ? (isAscending ? 36 : 24) : (rimGlowOpacity > 0 ? 16 : 10),
            x: 0,
            y: isCompleting ? (isAscending ? -10 : -4) : 4
        )
        .onAppear {
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
            withAnimation(.easeOut(duration: 0.25)) {
                pulseColor = activeAccentColor
                pulseOpacity = 0.20
                rimGlowColor = activeAccentColor
                rimGlowOpacity = 0.70
                scaleBreath = 1.008
            }
            withAnimation(.easeOut(duration: 1.1).delay(0.25)) {
                pulseOpacity = 0.0
                rimGlowOpacity = 0.0
                scaleBreath = 1.0
            }

        case .taskAdded:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                scaleBreath = 1.018
                rimGlowColor = activeAccentColor
                rimGlowOpacity = 0.55
                pulseColor = activeAccentColor
                pulseOpacity = 0.12
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                scaleBreath = 1.0
                rimGlowOpacity = 0.0
                pulseOpacity = 0.0
            }

        case .taskDeleted:
            withAnimation(.easeOut(duration: 0.22)) {
                pulseColor = removalAmber
                pulseOpacity = 0.14
                rimGlowColor = removalAmber
                rimGlowOpacity = 0.45
                scaleBreath = 0.996
            }
            withAnimation(.easeOut(duration: 0.75).delay(0.18)) {
                pulseOpacity = 0.0
                rimGlowOpacity = 0.0
                scaleBreath = 1.0
            }

        case .none:
            break
        }
    }
}
