import SwiftUI

public struct DotGridView: View {
    public let totalDays: Int
    public let daysElapsed: Int
    public let totalHours: Int
    public let hoursElapsed: Int
    public let hoursRemaining: Int
    public let isUnder24h: Bool
    public let isUnder48h: Bool
    public let isCompleting: Bool

    @Environment(\.theme) private var theme

    public init(
        totalDays: Int,
        daysElapsed: Int,
        totalHours: Int,
        hoursElapsed: Int,
        hoursRemaining: Int = 0,
        isUnder24h: Bool = false,
        isUnder48h: Bool = false,
        isCompleting: Bool = false
    ) {
        self.totalDays = totalDays
        self.daysElapsed = daysElapsed
        self.totalHours = totalHours
        self.hoursElapsed = hoursElapsed
        self.hoursRemaining = hoursRemaining
        self.isUnder24h = isUnder24h
        self.isUnder48h = isUnder48h
        self.isCompleting = isCompleting
    }

    private struct DotItem: Identifiable {
        let id: Int
        let elapsed: Bool
        let isLead: Bool
    }

    private var dotItems: [DotItem] {
        // 1. Hourly Sprint Mode for Short Deadlines (< 48 hours or <= 2 days)
        if isUnder24h || totalDays <= 1 {
            let totalUnits = 24
            let remaining = max(0, min(24, hoursRemaining > 0 ? hoursRemaining : 24 - hoursElapsed))
            let elapsed = 24 - remaining

            var items: [DotItem] = []
            var leadAssigned = false

            for i in 0..<totalUnits {
                let isPassed = i < elapsed
                var isLead = false
                if !isPassed && !leadAssigned {
                    isLead = true
                    leadAssigned = true
                }
                items.append(DotItem(id: i, elapsed: isPassed, isLead: isLead))
            }
            return items
        } else if isUnder48h || totalDays <= 2 {
            let totalUnits = 48
            let remaining = max(0, min(48, hoursRemaining > 0 ? hoursRemaining : 48 - hoursElapsed))
            let elapsed = 48 - remaining

            var items: [DotItem] = []
            var leadAssigned = false

            for i in 0..<totalUnits {
                let isPassed = i < elapsed
                var isLead = false
                if !isPassed && !leadAssigned {
                    isLead = true
                    leadAssigned = true
                }
                items.append(DotItem(id: i, elapsed: isPassed, isLead: isLead))
            }
            return items
        }

        // 2. Standard Daily Horizon Grid
        let totalUnits = totalDays
        let unitsElapsed = daysElapsed

        guard totalUnits > 0 && totalUnits <= 1095 else { return [] }

        var displayDots = totalUnits
        var sampleRate = 1

        if totalUnits > 365 {
            sampleRate = Int(ceil(Double(totalUnits) / 365.0))
            displayDots = Int(ceil(Double(totalUnits) / Double(sampleRate)))
        }
        if displayDots > 500 {
            sampleRate = Int(ceil(Double(totalUnits) / 180.0))
            displayDots = Int(ceil(Double(totalUnits) / Double(sampleRate)))
        }

        var items: [DotItem] = []
        var leadAssigned = false

        for i in 0..<displayDots {
            let originalUnit = i * sampleRate
            let elapsed = originalUnit < unitsElapsed
            var isLead = false

            if !elapsed && !leadAssigned {
                isLead = true
                leadAssigned = true
            }

            items.append(DotItem(id: i, elapsed: elapsed, isLead: isLead))
        }

        return items
    }

    private var dotSize: CGFloat {
        if isUnder24h || totalDays <= 1 { return 7 }
        if isUnder48h || totalDays <= 2 { return 6 }
        if totalDays <= 90 { return 5.5 }
        if totalDays <= 365 { return 4 }
        return 3
    }

    private var dotGap: CGFloat {
        if isUnder24h || totalDays <= 1 { return 5 }
        if isUnder48h || totalDays <= 2 { return 4.5 }
        if totalDays <= 90 { return 4 }
        return 3
    }

    public var body: some View {
        let items = dotItems
        let totalUnits = isUnder24h ? totalHours : totalDays

        if totalUnits > 0 && totalUnits <= 1095 {
            FlowLayout(spacing: dotGap) {
                ForEach(items) { item in
                    Circle()
                        .fill(isCompleting ? theme.accent : (item.elapsed ? theme.dotElapsed : theme.dotFilled))
                        .frame(width: dotSize, height: dotSize)
                        .scaleEffect(isCompleting ? 1.2 : 1.0)
                        .shadow(
                            color: isCompleting ? theme.accent.opacity(0.8) : (item.isLead ? theme.accent.opacity(0.6) : .clear),
                            radius: isCompleting ? 3 : (item.isLead ? 4 : 0),
                            x: 0,
                            y: 0
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isCompleting)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

/// Custom wrapping flow layout for dot matrix
private struct FlowLayout: Layout {
    var spacing: CGFloat

    init(spacing: CGFloat = 4) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            height = currentY + rowHeight
        }

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        // Compute rows to center-align them
        var rows: [[(subview: LayoutSubview, size: CGSize)]] = []
        var currentRow: [(subview: LayoutSubview, size: CGSize)] = []
        var currentRowWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > bounds.width && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                currentRowWidth = 0
            }
            currentRow.append((view, size))
            currentRowWidth += size.width + spacing
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        for row in rows {
            let totalRowWidth = row.reduce(0) { $0 + $1.size.width } + CGFloat(max(0, row.count - 1)) * spacing
            let startX = bounds.minX + max(0, (bounds.width - totalRowWidth) / 2)
            currentX = startX
            rowHeight = row.map(\.size.height).max() ?? 0

            for (view, size) in row {
                view.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
                currentX += size.width + spacing
            }
            currentY += rowHeight + spacing
        }
    }
}
