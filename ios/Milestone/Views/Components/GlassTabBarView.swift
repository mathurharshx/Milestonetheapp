import SwiftUI

public enum TabItem: Int, CaseIterable, Identifiable {
    case mission = 0
    case pomodoro = 1
    case archive = 2
    case settings = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .mission: return "Mission"
        case .pomodoro: return "Pomodoro"
        case .archive: return "Archive"
        case .settings: return "Settings"
        }
    }

    public var systemImage: String {
        switch self {
        case .mission: return "scope"
        case .pomodoro: return "hourglass"
        case .archive: return "archivebox"
        case .settings: return "gearshape"
        }
    }
}

public struct GlassTabBarView: View {
    @Binding public var selectedTab: TabItem
    @Environment(\.theme) private var theme

    public init(selectedTab: Binding<TabItem>) {
        self._selectedTab = selectedTab
    }

    private let barWidth: CGFloat = 216
    private let barHeight: CGFloat = 52
    private let tabCount: CGFloat = CGFloat(TabItem.allCases.count)

    public var body: some View {
        let pillWidth = (barWidth - 8) / tabCount
        let pillOffset = CGFloat(selectedTab.rawValue) * pillWidth

        ZStack(alignment: .leading) {
            // ── Outer Liquid Glass Shell ──
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    // Subtle ambient inner glass light
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.isDark ? 0.08 : 0.25),
                                    Color.clear,
                                    Color.white.opacity(theme.isDark ? 0.03 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    // Multi-stop Specular Rim Highlight (Directional Glass Reflection)
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(theme.isDark ? 0.45 : 0.8), location: 0.0),
                                    .init(color: Color.white.opacity(theme.isDark ? 0.15 : 0.3), location: 0.3),
                                    .init(color: Color.white.opacity(0.0), location: 0.6),
                                    .init(color: Color.white.opacity(theme.isDark ? 0.2 : 0.4), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                // Multi-tiered Liquid Elevation Shadow
                .shadow(
                    color: Color.black.opacity(theme.isDark ? 0.5 : 0.12),
                    radius: 20,
                    x: 0,
                    y: 10
                )
                .shadow(
                    color: Color.black.opacity(theme.isDark ? 0.3 : 0.06),
                    radius: 4,
                    x: 0,
                    y: 2
                )

            // ── Sliding Liquid Gel Capsule Indicator ──
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(theme.textPrimary)

                // Top Specular Glint Line on the Gel Pill
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDark ? 0.35 : 0.5),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .frame(width: pillWidth, height: barHeight - 8)
            .offset(x: pillOffset + 4)
            .animation(.spring(response: 0.34, dampingFraction: 0.68), value: selectedTab)

            // ── Tab Icon Items Row ──
            HStack(spacing: 0) {
                ForEach(TabItem.allCases) { tab in
                    let isSelected = tab == selectedTab

                    Button {
                        if selectedTab != tab {
                            HapticsManager.shared.selection()
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) {
                                selectedTab = tab
                            }
                        }
                    } label: {
                        ZStack {
                            // Subtle Luminescent Glow under active icon
                            if isSelected {
                                Circle()
                                    .fill(theme.background.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .blur(radius: 4)
                                    .transition(.opacity)
                            }

                            Image(systemName: tab.systemImage)
                                .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? theme.background : theme.textSecondary)
                                .scaleEffect(isSelected ? 1.12 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LiquidTabButtonStyle())
                }
            }
        }
        .frame(width: barWidth, height: barHeight)
        .padding(.bottom, 12)
    }
}

/// Custom button style with smooth fluid press-compression
private struct LiquidTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
