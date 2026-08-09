import SwiftUI

public struct QuoteModalView: View {
    public let quote: Quote?
    public let onContinue: () -> Void
    @Environment(\.theme) private var theme

    public init(quote: Quote?, onContinue: @escaping () -> Void) {
        self.quote = quote
        self.onContinue = onContinue
    }

    public var body: some View {
        ZStack {
            // Dimmed background backdrop
            Color.black.opacity(theme.isDark ? 0.8 : 0.4)
                .ignoresSafeArea()

            // Card
            VStack(spacing: 24) {
                // Checkmark badge
                Circle()
                    .stroke(theme.accent, lineWidth: 1.5)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    )
                    .padding(.top, 8)

                Text("MISSION ACCOMPLISHED")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(theme.accent)

                if let quote = quote {
                    VStack(spacing: 12) {
                        Text("\"\(quote.text)\"")
                            .font(.system(size: 19, weight: .regular, design: .serif))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .foregroundStyle(theme.textPrimary)
                            .padding(.horizontal, 16)

                        Text("— \(quote.author)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                    }
                }

                Button {
                    HapticsManager.shared.impact(.medium)
                    onContinue()
                } label: {
                    Text("CONTINUE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(theme.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.accent)
                        )
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
            )
            .padding(.horizontal, 24)
        }
    }
}
