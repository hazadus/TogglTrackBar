import SwiftUI

/// Часть меню с инфо о текущей записи времени и пунктом для её остановки.
struct CurrentTimeEntrySectionView: View {
    @EnvironmentObject var togglVM: TogglViewModel

    var body: some View {
        // TODO: добавить название проекта в скобках
        Text(
            "Сейчас: " + (togglVM.currentEntry?.description ?? "Без описания")
        ).foregroundStyle(.secondary)
        
        Button("Остановить") {
            Task {
                await stopCurrentEntry()
            }
        }
    }

    private func stopCurrentEntry() async {
        await togglVM.stopCurrentEntry()
    }
}
