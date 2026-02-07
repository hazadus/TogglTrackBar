import SwiftUI

/// Часть меню со статистикой работы за день и неделю.
struct TotalsSectionView: View {
    @EnvironmentObject var togglVM: TogglViewModel
    @EnvironmentObject var timeEntryTimer: TimeEntryTimer

    var body: some View {
        let elapsed = timeEntryTimer.elapsedSeconds

        TodayTotalRow(
            baseSeconds: togglVM.stats.todaySeconds,
            elapsedSeconds: elapsed,
            targetDailyHours: togglVM.targetDailyHours
        )

        WeekTotalRow(
            baseSeconds: togglVM.stats.weekSeconds,
            elapsedSeconds: elapsed,
            targetWeeklyHours: togglVM.targetWeeklyHours
        )
    }
}

// MARK: - Subviews
private struct TodayTotalRow: View {
    let baseSeconds: Int
    let elapsedSeconds: Int
    let targetDailyHours: Int

    @Environment(\.openURL) private var openURL

    var body: some View {
        let total = baseSeconds + elapsedSeconds
        let percentage =
            targetDailyHours > 0
            ? Int(Double(total) / Double(targetDailyHours * 3600) * 100)
            : 0
        let percentageFormatted =
            targetDailyHours > 0
            ? "(\(percentage)% от цели)"
            : ""

        Button(
            "Всего сегодня: \(Formatters.secondsAsTime(from: Double(total))) \(percentageFormatted)"
        ) {
            openURL(TogglURLs.timer)
        }
    }
}

private struct WeekTotalRow: View {
    let baseSeconds: Int
    let elapsedSeconds: Int
    let targetWeeklyHours: Int

    @Environment(\.openURL) private var openURL

    var body: some View {
        let total = baseSeconds + elapsedSeconds
        let percentage =
            targetWeeklyHours > 0
            ? Int(Double(total) / Double(targetWeeklyHours * 3600) * 100)
            : 0
        let percentageFormatted =
            targetWeeklyHours > 0
            ? "(\(percentage)% от цели)"
            : ""

        Button(
            "Всего на неделе: \(Formatters.secondsAsTime(from: Double(total))) \(percentageFormatted)"
        ) {
            openURL(TogglURLs.overview)
        }
    }
}
