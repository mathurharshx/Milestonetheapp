import SwiftUI

public struct HorizontalCalendarSliderView: View {
    @Binding public var selectedDate: Date
    @Binding public var hasTime: Bool

    @Environment(\.theme) private var theme

    private let calendar = Calendar.current
    private let numberOfDays = 35

    public init(selectedDate: Binding<Date>, hasTime: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._hasTime = hasTime
    }

    private var availableDates: [Date] {
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<numberOfDays).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfToday)
        }
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    private func dayName(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInTomorrow(date) {
            return "TOM"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date).uppercased()
        }
    }

    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func monthName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Quick Preset Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    PresetChip(title: "+1 DAY") {
                        selectPreset(daysToAdd: 1)
                    }
                    PresetChip(title: "+3 DAYS") {
                        selectPreset(daysToAdd: 3)
                    }
                    PresetChip(title: "+1 WEEK") {
                        selectPreset(daysToAdd: 7)
                    }
                    PresetChip(title: "+30 DAYS") {
                        selectPreset(daysToAdd: 30)
                    }
                }
                .padding(.horizontal, 2)
            }

            // Horizontal Date Slider
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableDates, id: \.self) { date in
                            let isSelected = isSameDay(selectedDate, date)

                            Button {
                                HapticsManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    updateSelectedDate(date)
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(dayName(for: date))
                                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                        .tracking(1)
                                        .foregroundStyle(isSelected ? theme.accent : theme.textTertiary)

                                    Text(dayNumber(for: date))
                                        .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                                        .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)

                                    Text(monthName(for: date))
                                        .font(.system(size: 9, weight: .semibold))
                                        .tracking(0.5)
                                        .foregroundStyle(isSelected ? theme.accent : theme.textTertiary.opacity(0.8))
                                }
                                .frame(width: 58, height: 72)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isSelected ? theme.accent.opacity(0.12) : theme.surfaceLight.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isSelected ? theme.accent : theme.border.opacity(0.5), lineWidth: isSelected ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .id(date)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
                .onAppear {
                    let startOfSelected = calendar.startOfDay(for: selectedDate)
                    proxy.scrollTo(startOfSelected, anchor: .center)
                }
            }

            // Time Selector (if active)
            if hasTime {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.accent)

                    Text("TARGET TIME")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(theme.textSecondary)

                    Spacer()

                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(theme.accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surfaceLight.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.border.opacity(0.5), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func updateSelectedDate(_ newDate: Date) {
        var comps = calendar.dateComponents([.year, .month, .day], from: newDate)
        let timeComps = calendar.dateComponents([.hour, .minute, .second], from: selectedDate)
        comps.hour = timeComps.hour ?? (hasTime ? 12 : 23)
        comps.minute = timeComps.minute ?? (hasTime ? 0 : 59)
        comps.second = timeComps.second ?? (hasTime ? 0 : 59)
        if let merged = calendar.date(from: comps) {
            selectedDate = merged
        }
    }

    private func selectPreset(daysToAdd: Int) {
        HapticsManager.shared.impact(.medium)
        let now = Date()
        if let target = calendar.date(byAdding: .day, value: daysToAdd, to: now) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                updateSelectedDate(target)
            }
        }
    }
}

private struct PresetChip: View {
    let title: String
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(theme.accent.opacity(0.10))
                )
                .overlay(
                    Capsule()
                        .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
