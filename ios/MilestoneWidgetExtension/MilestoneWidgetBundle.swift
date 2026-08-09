import WidgetKit
import SwiftUI

@main
struct MilestoneWidgetBundle: WidgetBundle {
    var body: some Widget {
        MilestoneDotMatrixWidget()
        MilestoneMissionWidget()
        MilestonePomodoroWidget()
        MilestoneMomentumWidget()
        PomodoroLiveActivity()
    }
}
