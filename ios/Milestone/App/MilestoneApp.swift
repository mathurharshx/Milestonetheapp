import SwiftUI

@main
struct MilestoneApp: App {
    @State private var missionStore = MissionStore()
    @State private var pomodoroStore = PomodoroStore()
    @State private var userStore = UserStore()
    @State private var themeStore = ThemeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(missionStore)
                .environment(pomodoroStore)
                .environment(userStore)
                .environment(themeStore)
        }
    }
}
