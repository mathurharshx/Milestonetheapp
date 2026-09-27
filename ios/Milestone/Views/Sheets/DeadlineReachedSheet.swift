import SwiftUI

/// A clean, brutalist resolution sheet presented when a mission's target date has passed.
/// Provides an objective tally of what was accomplished and empowers the user to either:
/// 1. "ARCHIVE MISSION": Conclude and record into the archive.
/// 2. "+24 HOURS" / "CUSTOM DATE": Extend the runway with renewed momentum.
public struct DeadlineReachedSheet: View {
    public let mission: Mission
    public let onArchive: () -> Void
    public let onExtend: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var isCustomDateExpanded: Bool = false
    @State private var customDate: Date = Date().addingTimeInterval(86400 * 3) // Default +3 days

    private var accentColor: Color {
        mission.category == .personal ? AppColors.personalEmerald : theme.accent
    }

    private var totalTasks: Int {
        mission.todos.count
    }

    private var completedTasks: Int {
        mission.todos.filter { $0.done }.count
    }

    private var completionPercent: Int {
        guard totalTasks > 0 else { return 100 }
        return Int((Double(completedTasks) / Double(totalTasks)) * 100)
    }

    public init(
        mission: Mission,
        onArchive: @escaping () -> Void,
        onExtend: @escaping (Date) -> Void
    ) {
        self.mission = mission
        self.onArchive = onArchive
        self.onExtend = onExtend
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                // Subtle Alive Dune Atmosphere
                AliveDuneAtmosphereView(
                    accentColor: accentColor,
                    secondaryColor: mission.category == .personal ? Color(red: 0x1A/255.0, green: 0x2E/255.0, blue: 0x22/255.0) : theme.surfaceLight,
                    intensity: 0.65
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // ── Top Icon Badge ──
                            ZStack {
                                Circle()
                                    .fill(accentColor.opacity(0.12))
                                    .frame(width: 64, height: 64)

                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(accentColor)
                            }
                            .padding(.top, 28)

                            // ── Header Text ──
                            VStack(spacing: 8) {
                                Text("DEADLINE REACHED")
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(3.5)
                                    .foregroundStyle(accentColor)

                                Text(mission.title)
                                    .font(.system(size: 28, weight: .semibold))
                                    .tracking(-0.6)
                                    .foregroundStyle(theme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)

                                Text("Time has elapsed for this mission. Review your progress and choose your next move.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }

                            // ── Objective Task Score Card ──
                            VStack(spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("TASK COMPLETION")
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(1.5)
                                            .foregroundStyle(theme.textTertiary)

                                        if totalTasks > 0 {
                                            Text("\(completedTasks) of \(totalTasks) Tasks Completed")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(theme.textPrimary)
                                        } else {
                                            Text("Open Runway Mission")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(theme.textPrimary)
                                        }
                                    }

                                    Spacer()

                                    Text("\(completionPercent)%")
                                        .font(.system(size: 24, weight: .light))
                                        .monospacedDigit()
                                        .foregroundStyle(accentColor)
                                }

                                // Brutalist Progress Track
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(theme.surfaceLight.opacity(0.8))
                                            .frame(height: 5)

                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(accentColor)
                                            .frame(width: geo.size.width * CGFloat(Double(completionPercent) / 100.0), height: 5)
                                    }
                                }
                                .frame(height: 5)

                                // Quick Tasks Checklist Preview
                                if !mission.todos.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(mission.todos) { todo in
                                            HStack(spacing: 10) {
                                                Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(todo.done ? accentColor : theme.textTertiary)

                                                Text(todo.text)
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundStyle(todo.done ? theme.textPrimary : theme.textSecondary)
                                                    .strikethrough(todo.done, color: theme.textTertiary)
                                                    .lineLimit(1)

                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(theme.surface.opacity(0.65))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(theme.border.opacity(0.4), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)

                            // ── Custom Date Picker (If expanded) ──
                            if isCustomDateExpanded {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("SELECT NEW TARGET DATE")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundStyle(theme.textTertiary)

                                    DatePicker(
                                        "",
                                        selection: $customDate,
                                        in: Date()...,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .datePickerStyle(.graphical)
                                    .tint(accentColor)

                                    Button {
                                        HapticsManager.shared.impact(.medium)
                                        onExtend(customDate)
                                        dismiss()
                                    } label: {
                                        Text("SET NEW TARGET & RESUME")
                                            .font(.system(size: 12, weight: .bold))
                                            .tracking(2)
                                            .foregroundStyle(theme.background)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 46)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(accentColor)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(theme.surface.opacity(0.7))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(accentColor.opacity(0.35), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                            }
                        }
                        .padding(.bottom, 24)
                    }

                    // ── Bottom Fixed Action Options ──
                    VStack(spacing: 10) {
                        // 1. Primary Action: Archive Mission
                        Button {
                            HapticsManager.shared.impact(.medium)
                            onArchive()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("ARCHIVE MISSION")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(2.5)
                            }
                            .foregroundStyle(theme.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(accentColor)
                            )
                        }
                        .buttonStyle(.plain)

                        // 2. Secondary Extensions Row
                        HStack(spacing: 10) {
                            // +24 Hours Quick Extension
                            Button {
                                HapticsManager.shared.impact(.light)
                                let newTarget = Date().addingTimeInterval(86400) // +24 hours
                                onExtend(newTarget)
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("+24 HOURS")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.4)
                                }
                                .foregroundStyle(theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.surfaceLight.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.border.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            // Custom Date Extension Toggle
                            Button {
                                HapticsManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    isCustomDateExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(isCustomDateExpanded ? "CLOSE" : "CUSTOM DATE")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.4)
                                }
                                .foregroundStyle(theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.surfaceLight.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.border.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(theme.background.opacity(0.95))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                    .foregroundStyle(theme.textTertiary)
                }
            }
        }
    }
}
