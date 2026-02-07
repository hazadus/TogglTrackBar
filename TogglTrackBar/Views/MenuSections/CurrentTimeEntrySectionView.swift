import SwiftUI

/// Часть меню с инфо о текущей записи времени и пунктом для её остановки.
struct CurrentTimeEntrySectionView: View {
    @EnvironmentObject var togglVM: TogglViewModel

    var body: some View {
        Text(
            currentEntryLabel()
        )
        .foregroundStyle(.secondary)

        Button("Остановить") {
            Task {
                await stopCurrentEntry()
            }
        }
    }

    private func stopCurrentEntry() async {
        await togglVM.stopCurrentEntry()
    }

    private func currentEntryLabel() -> String {
        guard let entry = togglVM.currentEntry else { return "Сейчас: Без описания" }

        var label = "Сейчас: " + (entry.description ?? "Без описания")

        if let id = entry.projectId,
            let projectName = togglVM.projectName(forId: id) {
            label += " (\(projectName))"
        }

        return label
    }
}
