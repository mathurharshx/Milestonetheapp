import SwiftUI

public struct RootView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var showSplash: Bool = true

    public init() {}

    public var body: some View {
        let tokens = themeStore.tokens(systemScheme: colorScheme)

        ZStack {
            tokens.background.ignoresSafeArea()

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            } else if !userStore.hasSeenOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        userStore.hasSeenOnboarding = true
                    }
                }
                .transition(.opacity)
                .zIndex(5)
            } else {
                MainTabView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: tokens.isDark)
        .environment(\.theme, tokens)
        .preferredColorScheme(themeStore.mode.colorScheme)
    }
}
