import WidgetKit
import SwiftUI

@main
struct MilestoneWidgetBundle: WidgetBundle {
    var body: some Widget {
        MilestoneDotMatrixWidget()
        MilestonePersonalDotMatrixWidget()
        MilestoneFullRunwayWidget()
        MilestoneMissionWidget()
        MilestonePomodoroWidget()
        PomodoroLiveActivity()
    }
}


