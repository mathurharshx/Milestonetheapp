import SwiftUI

@main
struct MilestoneApp: App {
    @State private var missionStore = MissionStore()
    @State private var pomodoroStore = PomodoroStore()
    @State private var userStore = UserStore()
    @State private var themeStore = ThemeStore()
    @State private var subscriptionStore = SubscriptionStore.shared
    @State private var soundscapeManager = SoundscapeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(missionStore)
                .environment(pomodoroStore)
                .environment(userStore)
                .environment(themeStore)
                .environment(subscriptionStore)
                .environment(soundscapeManager)
                .preferredColorScheme(.dark)
        }
    }
}
