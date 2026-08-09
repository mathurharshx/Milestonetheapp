import WidgetKit
import SwiftUI

@main
struct MilestoneWidgetBundle: WidgetBundle {
    var body: some Widget {
        MilestoneMissionWidget()
        MilestonePomodoroWidget()
    }
}
