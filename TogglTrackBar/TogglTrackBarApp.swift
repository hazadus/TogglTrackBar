import SwiftUI

@main
struct TogglTrackBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            MenuBarMenuView()
        } label: {
            MenuBarLabelView()
        }
        .menuBarExtraStyle(.menu)
    }
}
