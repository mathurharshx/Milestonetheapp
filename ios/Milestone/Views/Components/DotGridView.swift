import SwiftUI

public struct DotGridView: View {
    public let totalDays: Int
    public let daysElapsed: Int
    public let totalHours: Int
    public let hoursElapsed: Int
    public let isUnder24h: Bool
    public let isCompleting: Bool

    @Environment(\.theme) private var theme

    public init(
        totalDays: Int,
        daysElapsed: Int,
        totalHours: Int,
        hoursElapsed: Int,
        isUnder24h: Bool,
        isCompleting: Bool = false
    ) {
        self.totalDays = totalDays
        self.daysElapsed = daysElapsed
        self.totalHours = totalHours
        self.hoursElapsed = hoursElapsed
        self.isUnder24h = isUnder24h
        self.isCompleting = isCompleting
    }

    private struct DotItem: Identifiable {
        let id: Int
        let elapsed: Bool
        let isLead: Bool
    }

    private var dotItems: [DotItem] {
        let totalUnits = isUnder24h ? totalHours : totalDays
        let unitsElapsed = isUnder24h ? hoursElapsed : daysElapsed

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
        let totalUnits = isUnder24h ? totalHours : totalDays
        if totalUnits <= 24 { return 8 }
        if totalUnits <= 90 { return 6 }
        if totalUnits <= 365 { return 4 }
        return 3
    }

    private var dotGap: CGFloat {
        let totalUnits = isUnder24h ? totalHours : totalDays
        if totalUnits <= 24 { return 6 }
        if totalUnits <= 90 { return 4 }
        return 3
    }

    public var body: some View {
        let items = dotItems
        let totalUnits = isUnder24h ? totalHours : totalDays

        if totalUnits > 0 && totalUnits <= 1095 {
            FlowLayout(spacing: dotGap) {
                ForEach(items) { item in
                    let isFilled = isCompleting || !item.elapsed

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
