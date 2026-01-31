import SwiftUI

/// Содержимое главного выпадающего меню приложения.
struct MenuBarMenuView: View {
    @EnvironmentObject var togglVM: TogglViewModel

    var body: some View {
        if ProcessInfo.isPreview {
            // Выводим для исключения путаницы с реально запущенным приложением
            Text("PREVIEW MODE")
        }

        TotalsSectionView()

        if togglVM.currentEntry != nil {
            CurrentTimeEntrySectionView()
        } else {
            ContinueTimeEntrySectionView()
        }

        Divider()

        UserSectionView()

        Divider()

        UtilitySectionView()
    }
}
