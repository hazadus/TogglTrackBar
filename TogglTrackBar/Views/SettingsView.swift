import SwiftUI

/// Окно настроек приложения.
struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("targetDailyHours") private var targetDailyHours: Int = 0
    @AppStorage("targetWeeklyHours") private var targetWeeklyHours: Int = 0

    var body: some View {
        Form {
            // MARK: Раздел TogglTrack API
            Section {
                TextField(
                    // $ это binding для двусторонней связи с переменной
                    // Позволяет не только читать значение, но и записывать
                    text: $apiKey,
                    prompt: Text("your-secret-api-key"),
                ) {
                    Text("API Key")
                }
            } header: {
                Text("TogglTrack API")
            } footer: {
                HStack(spacing: 0) {
                    Text("Ключ можно получить в")
                        .foregroundStyle(.secondary)
                    Link(
                        " настройках профиля Toggl Track",
                        destination: URL(string: "https://track.toggl.com/profile")!)
                }
                .font(.footnote)
                // Растягиваем на всю ширину окна и центрируем контент
                .frame(maxWidth: .infinity, alignment: .center)
            }
            // MARK: Раздел "Цели"
            Section {
                TextField(
                    "Работа в день, часы",
                    value: $targetDailyHours,
                    format: .number,
                    prompt: Text("укажите целое число"),
                )
                TextField(
                    "Работа в неделю, часы",
                    value: $targetWeeklyHours,
                    format: .number,
                    prompt: Text("укажите целое число"),
                )
            } header: {
                Text("Цели")
            } footer: {
                VStack {
                    Text(
                        "Укажите количество часов, которые вы планируете работать в день и в неделю, для расчета процента выполнения. Для отключения процентов, установите нули."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

                    Spacer()
                    Divider()
                    Spacer()

                    Text("Для применения настроек, закройте это окно и перезапустите приложение.")
                }
                .multilineTextAlignment(.center)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .navigationTitle("Настройки")
    }
}

#Preview {
    SettingsView()
}
