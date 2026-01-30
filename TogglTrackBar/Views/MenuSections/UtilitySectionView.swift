import SwiftUI

/// Часть меню с утилитарными пунктами – настройки, о программе, выход и т.п.
struct UtilitySectionView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("О программе") {
            // Активируем приложение, чтобы окно появилось на переднем плане
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "about")
        }

        Button("Выход") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")  // Cmd+q
    }
}

#Preview {
    UtilitySectionView()
}
