import SwiftUI

/// Окно настроек приложения.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            // MARK: Раздел TogglTrack API
            Section {
                TextField(
                    // $ это binding для двусторонней связи с переменной
                    // Позволяет не только читать значение, но и записывать
                    text: $settings.apiKey,
                    prompt: Text("your-secret-api-key"),
                ) {
                    Text("API Key")
                }
            } header: {
                Text("TogglTrack API")
            } footer: {
                VStack {
                    HStack(spacing: 0) {
                        Text("Ключ можно получить в")
                            .foregroundStyle(.secondary)
                        Link(
                            " настройках профиля Toggl Track",
                            destination: URL(string: "https://track.toggl.com/profile")!)
                    }
                    // Растягиваем на всю ширину окна и центрируем контент
                    .frame(maxWidth: .infinity, alignment: .center)
                    Text("Перезапустите приложение после изменения ключа.")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
            }
            // MARK: Раздел "Метод помидора"
            Section {
                TextField(
                    "Размер помидора, мин.",
                    value: $settings.pomodoroSize,
                    format: .number,
                    prompt: Text("укажите целое число"),
                )
            } header: {
                Text("Метод помидора")
            } footer: {
                HStack(spacing: 0) {
                    Link(
                        "Метод помидора ",
                        destination: URL(string: "https://ru.wikipedia.org/wiki/Метод_помидора")!)
                    Text(" – 25 мин. сосредоточенной работы, 5 мин. перерыв.")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                // Растягиваем на всю ширину окна и центрируем контент
                .frame(maxWidth: .infinity, alignment: .center)
            }
            // MARK: Раздел "Цели"
            Section {
                TextField(
                    "Работа в день, часы",
                    value: $settings.targetDailyHours,
                    format: .number,
                    prompt: Text("укажите целое число"),
                )
                TextField(
                    "Работа в неделю, часы",
                    value: $settings.targetWeeklyHours,
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
        .environmentObject(AppSettings())
}
