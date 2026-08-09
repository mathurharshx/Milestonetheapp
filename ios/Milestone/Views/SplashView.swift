import SwiftUI

public struct SplashView: View {
    public let onComplete: () -> Void
    @Environment(\.theme) private var theme

    @State private var titleOpacity: Double = 1.0
    @State private var mainOpacity: Double = 1.0
    @State private var mainOffset: CGFloat = 0.0
    @State private var bgOpacity: Double = 1.0

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Background
            theme.background
                .ignoresSafeArea()
                .opacity(bgOpacity)

            // Top Title
            VStack {
                Text("MILESTONE")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(6)
                    .foregroundStyle(theme.textPrimary.opacity(0.65))
                    .padding(.top, 70)
                    .opacity(titleOpacity)

                Spacer()
            }

            // Center Main Text
            VStack {
                Text("One mission.\nThat's it.")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .tracking(-0.5)
                    .foregroundStyle(theme.textPrimary)
                    .offset(y: mainOffset)
                    .opacity(mainOpacity)
            }
        }
        .onAppear {
            // 1. Fade title at 1.0s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    titleOpacity = 0.0
                }
            }

            // 2. Translate and fade main text at 1.2s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    mainOffset = -8
                    mainOpacity = 0.0
                    bgOpacity = 0.0
                }
            }

            // 3. Complete at 1.6s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                onComplete()
            }
        }
    }
}
