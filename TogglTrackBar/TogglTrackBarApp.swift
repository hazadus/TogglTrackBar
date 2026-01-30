import SwiftUI

@main
struct TogglTrackBarApp: App {
    init() {
        NotificationService.shared.requestAuthorization()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenuView()
        } label: {
            MenuBarLabelView()
        }
        .menuBarExtraStyle(.menu)

        Window("О программе", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
