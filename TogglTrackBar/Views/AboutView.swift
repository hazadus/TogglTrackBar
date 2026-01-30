import SwiftUI

/// Окно "О программе".
struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            // MARK: Иконка и название
            HStack(spacing: 12) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("TogglTrackBar")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Версия \(AppInfo.version) (\(AppInfo.build))")
                }
            }

            Divider()

            // MARK: Детальная информация
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Bundle ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(AppInfo.bundleIdentifier)
                }
                GridRow {
                    Text("О проекте")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("GitHub", destination: URL(string: "https://github.com/hazadus/TogglTrackBar")!)
                }
                GridRow {
                    Text("Автор")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("Александр Голдовский", destination: URL(string: "https://amgold.ru")!)
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 320, height: 200)
    }
}

#Preview {
    AboutView()
}
