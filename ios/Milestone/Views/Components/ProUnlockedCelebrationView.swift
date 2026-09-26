import SwiftUI

public struct ProUnlockedCelebrationView: View {
    public let onDismiss: () -> Void
    @Environment(\.theme) private var theme

    @State private var appearScale: CGFloat = 0.94
    @State private var appearOpacity: Double = 0.0

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Ultra-Dark Minimalist Dimmer
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Sleek Minimalist Badge
                ZStack {
                    Circle()
                        .fill(theme.surfaceLight.opacity(0.5))
                        .frame(width: 72, height: 72)

                    Circle()
                        .stroke(theme.border.opacity(0.35), lineWidth: 1)
                        .frame(width: 72, height: 72)

                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }

                // Professional Typography
                VStack(spacing: 8) {
                    Text("MILESTONE PRO")
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(2.5)
                        .foregroundStyle(theme.accent)

                    Text("Welcome to Pro")
                        .font(.system(size: 23, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(theme.textPrimary)

                    Text("All features, soundscapes, and dedicated widgets are now active.")
                        .font(.system(size: 13, weight: .regular))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 16)
                }

                // Clean Primary Action
                Button {
                    HapticsManager.shared.impact(.light)
                    onDismiss()
                } label: {
                    Text("CONTINUE")
                        .font(.system(size: 12.5, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(theme.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.accent)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(theme.border.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(appearScale)
            .opacity(appearOpacity)
            .padding(.horizontal, 28)
        }
        .onAppear {
            HapticsManager.shared.notification(.success)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
        }
    }
}

