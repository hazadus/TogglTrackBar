import SwiftUI

/// Комонент ссылки, при наведении на которую изменяется указатель мыши.
struct HoverLink: View {
    let title: String
    let url: URL

    var body: some View {
        Link(title, destination: url)
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}
