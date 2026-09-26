import SwiftUI

public struct ProUnlockedCelebrationView: View {
    public let onDismiss: () -> Void
    @Environment(\.theme) private var theme

    @State private var appearScale: CGFloat = 0.8
    @State private var appearOpacity: Double = 0.0
    @State private var crownRotation: Double = -12.0
    @State private var pulseAura: Bool = false

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Glowing Ember Atmosphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0).opacity(pulseAura ? 0.35 : 0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(pulseAura ? 1.15 : 0.95)

            VStack(spacing: 20) {
                // Crown Badge
                ZStack {
                    Circle()
                        .fill(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0).opacity(0.18))
                        .frame(width: 90, height: 90)

                    Circle()
                        .stroke(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0).opacity(0.4), lineWidth: 1.5)
                        .frame(width: 90, height: 90)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0))
                        .rotationEffect(.degrees(crownRotation))
                }

                VStack(spacing: 6) {
                    Text("PRO ACTIVATED")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(3.5)
                        .foregroundStyle(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0))

                    Text("Full Arsenal Unlocked")
                        .font(.system(size: 26, weight: .bold))
                        .tracking(-0.5)
                        .foregroundStyle(Color.white)

                    Text("Dual-Pillar Widgets, ADHD Soundscapes, Dual Missions, and Cold Vault are now fully at your command.")
                        .font(.system(size: 13, weight: .regular))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.65))
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }

                Button {
                    HapticsManager.shared.impact(.light)
                    onDismiss()
                } label: {
                    Text("BEGIN")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(2.0)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.top, 12)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0x14/255.0, green: 0x14/255.0, blue: 0x16/255.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(red: 0xF9/255.0, green: 0x73/255.0, blue: 0x16/255.0).opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(appearScale)
            .opacity(appearOpacity)
            .padding(.horizontal, 24)
        }
        .onAppear {
            HapticsManager.shared.notification(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                appearScale = 1.0
                appearOpacity = 1.0
                crownRotation = 0.0
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseAura = true
            }
        }
    }
}
