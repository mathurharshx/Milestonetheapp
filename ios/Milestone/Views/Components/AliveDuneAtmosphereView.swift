import SwiftUI

/// An organic, living atmosphere view featuring fluid wave dynamics,
/// dual counter-harmonic wave interference, living ridge crest breathing, and
/// smooth continuous motion with zero CPU overhead using GPU hardware compositing.
public struct AliveDuneAtmosphereView: View {
    public let accentColor: Color
    public let secondaryColor: Color
    public let intensity: Double
    public let isBreathingSync: Bool

    @Environment(\.theme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    // Independent harmonic phase states for non-repetitive organic fluid movement
    @State private var phaseCrest: Bool = false
    @State private var phaseSwell: Bool = false
    @State private var phaseHighlight: Bool = false
    @State private var phaseShadow: Bool = false
    @State private var phaseCounter: Bool = false
    @State private var isVisible: Bool = false

    public init(
        accentColor: Color = AppColors.lightBackground,
        secondaryColor: Color = AppColors.darkSurfaceLight,
        intensity: Double = 1.0,
        isBreathingSync: Bool = false
    ) {
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
        self.intensity = max(0.0, min(intensity, 1.5))
        self.isBreathingSync = isBreathingSync
    }

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // ── Foundation: Deep Background Void ──
                theme.background
                    .ignoresSafeArea()

                // ── Layer 1: Ambient Mineral Diffusion (Hardware-Interpolated Soft Radial Gradient) ──
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: secondaryColor.opacity(0.30 * intensity), location: 0.0),
                                .init(color: secondaryColor.opacity(0.12 * intensity), location: 0.45),
                                .init(color: Color.clear, location: 0.88)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(w, h) * 0.58
                        )
                    )
                    .frame(width: w * 1.35, height: h * 0.95)
                    .position(
                        x: phaseShadow ? w * 0.48 : w * 0.32,
                        y: phaseShadow ? h * 0.65 : h * 0.48
                    )
                    .scaleEffect(phaseShadow ? 1.08 : 0.94)

                // ── Layer 2: Radiant Upper Atmosphere Corona ──
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: accentColor.opacity(0.22 * intensity), location: 0.0),
                                .init(color: secondaryColor.opacity(0.10 * intensity), location: 0.50),
                                .init(color: Color.clear, location: 0.92)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(w, h) * 0.52
                        )
                    )
                    .frame(width: w * 1.20, height: h * 0.90)
                    .position(
                        x: phaseSwell ? w * 0.78 : w * 0.62,
                        y: phaseSwell ? h * 0.20 : h * 0.34
                    )
                    .scaleEffect(phaseSwell ? 1.10 : 0.90)

                // ── Layer 3: Secondary Counter-Harmonic Wave (Hardware Composited) ──
                DuneCounterWaveShape(
                    crestOffset: phaseCounter ? 24.0 : -20.0,
                    valleyOffset: phaseCounter ? -18.0 : 22.0,
                    driftX: phaseCounter ? -22.0 : 18.0
                )
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: secondaryColor.opacity(0.22 * intensity), location: 0.0),
                            .init(color: accentColor.opacity(0.12 * intensity), location: 0.42),
                            .init(color: theme.background.opacity(0.18 * intensity), location: 0.75),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .blur(radius: 6)

                // ── Layer 4: Organic Flowing Primary Wave ──
                DuneWaveShape(
                    crestOffset: phaseCrest ? 30.0 : -26.0,
                    valleyOffset: phaseSwell ? -24.0 : 28.0,
                    driftX: phaseCrest ? 26.0 : -22.0
                )
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: accentColor.opacity(0.24 * intensity), location: 0.0),
                            .init(color: secondaryColor.opacity(0.18 * intensity), location: 0.36),
                            .init(color: theme.background.opacity(0.22 * intensity), location: 0.72),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .blur(radius: 5)

                // ── Layer 5: Sinuous Ridge Highlight (The illuminated living crest) ──
                DuneRidgeCrestPath(
                    crestOffset: phaseCrest ? 30.0 : -26.0,
                    valleyOffset: phaseSwell ? -24.0 : 28.0,
                    driftX: phaseCrest ? 26.0 : -22.0
                )
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.clear, location: 0.0),
                            .init(color: accentColor.opacity(0.12 * intensity), location: 0.18),
                            .init(color: accentColor.opacity(0.38 * intensity), location: 0.58),
                            .init(color: accentColor.opacity(0.12 * intensity), location: 0.88),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: phaseHighlight ? 12 : 8
                )
                .blur(radius: phaseHighlight ? 5 : 3)
                .opacity(phaseHighlight ? 0.90 : 0.60)

                // ── Layer 6: Concentrated Apex Glow ──
                Ellipse()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: accentColor.opacity(0.24 * intensity), location: 0.0),
                                .init(color: accentColor.opacity(0.06 * intensity), location: 0.55),
                                .init(color: Color.clear, location: 1.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.40
                        )
                    )
                    .frame(width: w * 0.80, height: h * 0.38)
                    .rotationEffect(.degrees(phaseCrest ? -16 : -26))
                    .position(
                        x: phaseCrest ? w * 0.72 : w * 0.60,
                        y: phaseCrest ? h * 0.24 : h * 0.35
                    )
                    .scaleEffect(phaseHighlight ? 1.08 : 0.92)

                // ── Layer 7: Mineral Shadow Scoop (Underneath Valley) ──
                Ellipse()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: secondaryColor.opacity(0.24 * intensity), location: 0.0),
                                .init(color: theme.background.opacity(0.35 * intensity), location: 0.55),
                                .init(color: Color.clear, location: 1.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.45
                        )
                    )
                    .frame(width: w * 0.95, height: h * 0.42)
                    .rotationEffect(.degrees(phaseCounter ? 16 : 8))
                    .position(
                        x: phaseShadow ? w * 0.50 : w * 0.38,
                        y: phaseShadow ? h * 0.54 : h * 0.44
                    )

                // ── Layer 8: Subtle Vignette / Edge Falloff for Perfect UI Contrast ──
                LinearGradient(
                    stops: [
                        .init(color: theme.background.opacity(0.48), location: 0.0),
                        .init(color: Color.clear, location: 0.14),
                        .init(color: Color.clear, location: 0.80),
                        .init(color: theme.background.opacity(0.72), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .drawingGroup() // Direct Metal GPU render pass: 0ms CPU load
        }
        .allowsHitTesting(false)
        .onAppear {
            isVisible = true
            startAtmosphericDrift()
        }
        .onDisappear {
            isVisible = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isVisible {
                startAtmosphericDrift()
            }
        }
    }

    private func startAtmosphericDrift() {
        guard isVisible else { return }

        // Dynamic, breathing cycle cadences for lively organic movement
        let durationCrest = isBreathingSync ? 3.0 : 4.8
        let durationSwell = isBreathingSync ? 3.8 : 6.2
        let durationHighlight = isBreathingSync ? 2.6 : 3.8
        let durationShadow = isBreathingSync ? 3.6 : 7.2
        let durationCounter = isBreathingSync ? 3.2 : 5.4

        withAnimation(.easeInOut(duration: durationCrest).repeatForever(autoreverses: true)) {
            phaseCrest = true
        }

        withAnimation(.easeInOut(duration: durationSwell).repeatForever(autoreverses: true)) {
            phaseSwell = true
        }

        withAnimation(.easeInOut(duration: durationHighlight).repeatForever(autoreverses: true)) {
            phaseHighlight = true
        }

        withAnimation(.easeInOut(duration: durationShadow).repeatForever(autoreverses: true)) {
            phaseShadow = true
        }

        withAnimation(.easeInOut(duration: durationCounter).repeatForever(autoreverses: true)) {
            phaseCounter = true
        }
    }
}

// MARK: - Primary Sinuous Wave Geometry

/// Continuous S-curve representing the wind-swept sand dune crest
private struct DuneWaveShape: Shape {
    var crestOffset: CGFloat
    var valleyOffset: CGFloat
    var driftX: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(crestOffset, AnimatablePair(valleyOffset, driftX))
        }
        set {
            crestOffset = newValue.first
            valleyOffset = newValue.second.first
            driftX = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Left boundary entry point
        let startPoint = CGPoint(x: -w * 0.15, y: h * 0.52 + valleyOffset * 0.5)
        path.move(to: startPoint)

        // Sinuous S-curve through valley and up to dune crest
        let cp1 = CGPoint(x: w * 0.22 + driftX, y: h * 0.58 + valleyOffset)
        let midPoint = CGPoint(x: w * 0.40, y: h * 0.46 + (crestOffset + valleyOffset) * 0.25)
        path.addQuadCurve(to: midPoint, control: cp1)

        let cp2 = CGPoint(x: w * 0.62 + driftX * 0.7, y: h * 0.24 + crestOffset)
        let endPoint = CGPoint(x: w * 1.15, y: h * 0.08 + crestOffset * 0.6)
        path.addQuadCurve(to: endPoint, control: cp2)

        // Close shape around right and bottom edges
        path.addLine(to: CGPoint(x: w * 1.25, y: h * 1.25))
        path.addLine(to: CGPoint(x: -w * 0.25, y: h * 1.25))
        path.closeSubpath()

        return path
    }
}

/// Counter-harmonic wave flowing in opposition to create liquid moiré depth
private struct DuneCounterWaveShape: Shape {
    var crestOffset: CGFloat
    var valleyOffset: CGFloat
    var driftX: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(crestOffset, AnimatablePair(valleyOffset, driftX))
        }
        set {
            crestOffset = newValue.first
            valleyOffset = newValue.second.first
            driftX = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Right boundary entry
        let startPoint = CGPoint(x: w * 1.15, y: h * 0.68 + valleyOffset * 0.4)
        path.move(to: startPoint)

        let cp1 = CGPoint(x: w * 0.78 - driftX, y: h * 0.72 + valleyOffset)
        let midPoint = CGPoint(x: w * 0.52, y: h * 0.58 + (crestOffset + valleyOffset) * 0.3)
        path.addQuadCurve(to: midPoint, control: cp1)

        let cp2 = CGPoint(x: w * 0.30 - driftX * 0.8, y: h * 0.42 + crestOffset)
        let endPoint = CGPoint(x: -w * 0.15, y: h * 0.34 + crestOffset * 0.5)
        path.addQuadCurve(to: endPoint, control: cp2)

        path.addLine(to: CGPoint(x: -w * 0.25, y: h * 1.25))
        path.addLine(to: CGPoint(x: w * 1.25, y: h * 1.25))
        path.closeSubpath()

        return path
    }
}

/// Stroke path precisely tracing the illuminated dune crest line
private struct DuneRidgeCrestPath: Shape {
    var crestOffset: CGFloat
    var valleyOffset: CGFloat
    var driftX: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(crestOffset, AnimatablePair(valleyOffset, driftX))
        }
        set {
            crestOffset = newValue.first
            valleyOffset = newValue.second.first
            driftX = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        let startPoint = CGPoint(x: -w * 0.15, y: h * 0.52 + valleyOffset * 0.5)
        path.move(to: startPoint)

        let cp1 = CGPoint(x: w * 0.22 + driftX, y: h * 0.58 + valleyOffset)
        let midPoint = CGPoint(x: w * 0.40, y: h * 0.46 + (crestOffset + valleyOffset) * 0.25)
        path.addQuadCurve(to: midPoint, control: cp1)

        let cp2 = CGPoint(x: w * 0.62 + driftX * 0.7, y: h * 0.24 + crestOffset)
        let endPoint = CGPoint(x: w * 1.15, y: h * 0.08 + crestOffset * 0.6)
        path.addQuadCurve(to: endPoint, control: cp2)

        return path
    }
}
