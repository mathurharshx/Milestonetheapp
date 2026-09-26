import WidgetKit
import SwiftUI

@main
struct MilestoneWidgetBundle: WidgetBundle {
    var body: some Widget {
        MilestoneDotMatrixWidget()
        MilestoneWorkDotMatrixWidget()
        MilestonePersonalDotMatrixWidget()
        MilestoneMissionWidget()
        MilestonePomodoroWidget()
        PomodoroLiveActivity()
    }
}

