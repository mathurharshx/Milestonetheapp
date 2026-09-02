import SwiftUI

public struct VictoryCardView: View {
    public let mission: Mission
    public let quote: Quote?
    public let theme: ThemeTokens

    public init(mission: Mission, quote: Quote?, theme: ThemeTokens) {
        self.mission = mission
        self.quote = quote
        self.theme = theme
    }

    private var totalDays: Int {
        DateCalculations.getTotalDays(createdAt: mission.createdAt, targetDate: mission.targetDate)
    }

    private var completedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date()).uppercased()
    }

    public var body: some View {
        ZStack {
            // Obsidian Base
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.10),
                    Color(red: 0.05, green: 0.05, blue: 0.05),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ambient Gold Radial Glow
            RadialGradient(
                colors: [theme.accent.opacity(0.18), Color.clear],
                center: .top,
                startRadius: 40,
                endRadius: 360
            )

            // Luxury Precision Inset Border
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [theme.accent.opacity(0.6), theme.border.opacity(0.3), theme.accent.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(16)

            VStack(spacing: 0) {
                // Header Monogram
                HStack(spacing: 8) {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 7, height: 7)

                    Text("MILESTONE")
                        .font(.system(size: 11, weight: .black))
                        .tracking(4)
                        .foregroundStyle(theme.textPrimary)

                    Spacer()

                    Text("PROOF OF VICTORY")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2.5)
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(theme.accentDim)
                        )
                }
                .padding(.horizontal, 36)
                .padding(.top, 44)

                Spacer()

                // Wax Seal Hero
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.14))
                        .frame(width: 104, height: 104)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [theme.accent, theme.textPrimary, theme.accent, theme.textTertiary],
                                center: .center
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 82, height: 82)

                    Circle()
                        .fill(theme.surface)
                        .frame(width: 76, height: 76)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accent, theme.accent.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.bottom, 22)

                // Mission Title
                Text(mission.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 12)

                Text("CONQUERED • \(completedDateString)")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(theme.accent)
                    .padding(.bottom, 28)

                // Stats Metrics Trio
                HStack(spacing: 12) {
                    MetricBox(
                        label: "DAYS",
                        value: "\(totalDays)",
                        theme: theme
                    )

                    MetricBox(
                        label: "TASKS",
                        value: "\(mission.todos.count)",
                        theme: theme
                    )

                    MetricBox(
                        label: "STATUS",
                        value: "100%",
                        theme: theme
                    )
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 28)

                // Stoic Quote
                if let quote = quote {
                    VStack(spacing: 8) {
                        Text("\"\(quote.text)\"")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .italic()
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)

                        Text("— \(quote.author.uppercased())")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 24)
                }

                Spacer()

                // Watermark Footer
                VStack(spacing: 4) {
                    Text("ONE MISSION AT A TIME")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(theme.textTertiary.opacity(0.7))

                    Text("milestone.app")
                        .font(.system(size: 8, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(theme.textTertiary.opacity(0.4))
                }
                .padding(.bottom, 40)
            }
        }
        .frame(width: 360, height: 640)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

private struct MetricBox: View {
    let label: String
    let value: String
    let theme: ThemeTokens

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.textPrimary)

            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.surfaceLight.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.border.opacity(0.6), lineWidth: 1)
        )
    }
}
