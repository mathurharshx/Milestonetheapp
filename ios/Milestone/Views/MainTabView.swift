import SwiftUI

public struct MainTabView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.theme) private var theme

    public init() {}

    public var body: some View {
        @Bindable var store = userStore

        TabView(selection: $store.selectedTab) {
            // Tab 0: Pomodoro
            NavigationStack {
                PomodoroTabView()
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "hourglass")
                Text("Pomodoro")
            }
            .tag(TabItem.pomodoro)

            // Tab 1: Tasks
            NavigationStack {
                TasksTabView()
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "checklist")
                Text("Tasks")
            }
            .tag(TabItem.tasks)

            // Tab 2: Mission (Centerpiece)
            NavigationStack {
                MissionTabView(onNavigateToArchive: {
                    userStore.selectedTab = .archive
                })
                .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "scope")
                Text("Mission")
            }
            .tag(TabItem.mission)

            // Tab 3: Archive
            NavigationStack {
                ArchiveTabView()
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "archivebox")
                Text("Archive")
            }
            .tag(TabItem.archive)

            // Tab 4: Settings
            NavigationStack {
                SettingsTabView()
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            .tag(TabItem.settings)
        }
        .tint(theme.textPrimary)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}
