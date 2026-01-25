import SwiftUI

/// Часть меню с утилитарными пунктами – настройки, выход и т.п.
struct UtilitySectionView: View {
    var body: some View {
        Button("Выход") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")  // Cmd+q
    }
}

#Preview {
    UtilitySectionView()
}
