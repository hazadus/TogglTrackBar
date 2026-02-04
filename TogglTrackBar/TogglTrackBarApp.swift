import Combine
import SwiftUI

@main
struct TogglTrackBarApp: App {
    // @StateObject — property wrapper, который создаёт и хранит объект ObservableObject.
    // SwiftUI не пересоздаёт его при перерисовке View
    /// ViewModel для данных TogglTrack API
    @StateObject private var togglVM: TogglViewModel
    /// Таймер для расчета продолжительности текущей записи времени
    @StateObject private var timeEntryTimer: TimeEntryTimer
    /// Настройки приложения, синхронизируемые с AppStorage
    @StateObject private var settings: AppSettings

    init() {
        NotificationService.shared.requestAuthorization()

        let appSettings = AppSettings()
        _settings = StateObject(wrappedValue: appSettings)

        let targetDailyHours = appSettings.targetDailyHours
        let targetWeeklyHours = appSettings.targetWeeklyHours

        // TODO: apiKey -> AppSettings
        // Читаем из UserDefaults (туда же пишет @AppStorage в виде настроек приложения)
        let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""

        let api = TogglAPI(apiKey: apiKey)

        // @StateObject генерирует приватное свойство _togglVM типа StateObject<TogglViewModel>.
        // Свойство togglVM — это computed property (get-only), поэтому присваивать ему значение
        // нельзя. Инициализация происходит через _togglVM = StateObject(wrappedValue: ...).
        let timer = TimeEntryTimer()
        _timeEntryTimer = StateObject(wrappedValue: timer)

        let pomodoroService = PomodoroService(notificationService: .shared)

        let viewModel = TogglViewModel(
            togglAPI: api,
            menuTimer: timer,
            settings: appSettings,
            pomodoroService: pomodoroService,
            targetDailyHours: targetDailyHours,
            targetWeeklyHours: targetWeeklyHours,
        )
        _togglVM = StateObject(wrappedValue: viewModel)
    }

    var body: some Scene {
        // Объекты инжектируются в окружение, и доступны во всех нижестоящих views.
        // @EnvironmentObject ищет объект по типу, а не по имени переменной.
        // Следствие: в окружении может быть только один объект каждого типа.
        // Если вызвать .environmentObject() дважды с разными экземплярами одного
        // типа — второй перезапишет первый.
        MenuBarExtra {
            MenuBarMenuView()
                .environmentObject(togglVM)
                .environmentObject(timeEntryTimer)
        } label: {
            MenuBarLabelView()
                .environmentObject(togglVM)
                .environmentObject(timeEntryTimer)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }

        Window("О программе", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
