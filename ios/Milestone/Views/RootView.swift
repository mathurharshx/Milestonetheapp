import SwiftUI

public struct RootView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(ThemeStore.self) private var themeStore
    @Environment(PomodoroStore.self) private var pomodoroStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash: Bool = true

    public init() {}

    public var body: some View {
        let tokens = themeStore.tokens(systemScheme: colorScheme)

        ZStack {
            tokens.background
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.28), value: tokens.isDark)

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
        .environment(\.theme, tokens)
        .preferredColorScheme(.dark)
        .onAppear {
            themeStore.syncToWidget()
            pomodoroStore.syncFromWidget()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                themeStore.syncToWidget()
                pomodoroStore.syncFromWidget()
            }
        }
        .onOpenURL { url in
            showSplash = false
            pomodoroStore.syncFromWidget()
            userStore.handleDeepLink(url: url)
        }
        .sheet(isPresented: Bindable(userStore).showPaywallSheet) {
            PaywallSheet()
        }
    }
}
