import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: TabItem = .mission
    @Environment(\.theme) private var theme

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Mission
            NavigationStack {
                MissionTabView(onNavigateToArchive: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = .archive
                    }
                })
                .toolbarBackground(theme.background, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "scope")
                Text("Mission")
            }
            .tag(TabItem.mission)

            // Tab 2: Pomodoro
            NavigationStack {
                PomodoroTabView()
                    .toolbarBackground(theme.background, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "hourglass")
                Text("Pomodoro")
            }
            .tag(TabItem.pomodoro)

            // Tab 3: Archive
            NavigationStack {
                ArchiveTabView()
                    .toolbarBackground(theme.background, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "archivebox")
                Text("Archive")
            }
            .tag(TabItem.archive)

            // Tab 4: Settings
            NavigationStack {
                SettingsTabView()
                    .toolbarBackground(theme.background, for: .navigationBar)
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            .tag(TabItem.settings)
        }
        .tint(theme.textPrimary)
        .toolbarBackground(theme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
