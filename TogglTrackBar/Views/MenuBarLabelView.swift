import SwiftUI

/// Значок в строке меню macOS.
struct MenuBarLabelView: View {
    @EnvironmentObject var togglVM: TogglViewModel
    @EnvironmentObject var timeEntryTimer: TimeEntryTimer

    var body: some View {
        Group {
            Image(systemName: "timer")

            if let elapsedTime = timeEntryTimer.elapsedTimeText {
                // Обновляется при каждом "тике" таймера, когда он запущен
                Text(elapsedTime)
            }
        }.task {
            await togglVM.loadIfNeeded()
        }
    }
}
