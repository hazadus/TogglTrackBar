import SwiftUI

/// Подменю "Продолжить" со списком записей времени, по каждой из которых можно кликнуть для "продолжения".
struct ContinueTimeEntrySectionView: View {
    @EnvironmentObject var togglVM: TogglViewModel

    var body: some View {
        Menu("Продолжить") {
            if togglVM.isLoading {
                Text("Загрузка данных...")
                    .foregroundStyle(.secondary)
            } else if togglVM.latestEntries.isEmpty {
                Text("Нет записей")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(togglVM.latestUniqueEntries) { entry in
                    Button {
                        Task {
                            await continueEntry(entry)
                        }
                    } label: {
                        Text(entryLabel(for: entry))
                    }
                }
            }
        }
    }

    private func entryLabel(for entry: TogglTimeEntry) -> String {
        let description = entry.description ?? "Нет описания"
        
        guard let id = entry.projectId,
            let name = togglVM.projects[id]?.name
        else {
            return description
        }
        
        return "\(description) (\(name))"
    }

    private func continueEntry(_ entry: TogglTimeEntry) async {
        await togglVM.continueEntry(from: entry)
    }
}
