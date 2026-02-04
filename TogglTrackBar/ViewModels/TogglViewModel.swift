import AppKit
import Combine
import Foundation
import os

/// @MainActor - атрибут, гарантирующий выполнение всех методов на главном потоке. Важно для UI!
@MainActor
final class TogglViewModel: ObservableObject {
    /// ObservableObject - протокол: "я могу публиковать изменения, SwiftUI должен за мной следить"

    /// Полная информация о пользователе из TogglTrack API со связанными данными
    @Published private(set) var user: TogglUser?  // (set) не даёт изменять напрямую
    /// Записи времени за последние daysToLoad
    @Published private(set) var latestEntries: [TogglTimeEntry] = []
    /// Уникальные записи времени за последние daysToLoad. Используются в резделе меню "Продолжить".
    @Published private(set) var latestUniqueEntries: [TogglTimeEntry] = []
    /// Текущая запись времени (если есть)
    @Published private(set) var currentEntry: TogglTimeEntry?
    /// Статистика записей времени, рассчитываемая приложением локально
    @Published private(set) var stats = TimeStats()
    /// Сведения о rate limits от TogglTrack API
    @Published private(set) var rateLimit: RateLimitInfo?
    /// Флаги загрузки и завершения загрузки данных из TogglTrack API
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoaded = false

    private let settings: AppSettings
    private let pomodoroService: PomodoroService
    private var togglAPI: TogglAPI
    private var menuTimer: TimeEntryTimer

    /// AnyCancellable — обёртка для подписки Combine. Когда объект уничтожается, подписка автоматически отменяется
    /// Set<AnyCancellable> — коллекция для хранения всех подписок. Стандартный паттерн в Combine
    private var cancellables = Set<AnyCancellable>()

    /// Словарь соответствий id проекта -> данные проекта
    private(set) var projects: [Int: TogglProject] = [:]
    /// Целевые значения по времени работы пользователя в день и в неделю
    private(set) var targetDailyHours = 0
    private(set) var targetWeeklyHours = 0

    /// Количество дней, за которые будут загружаться записи времени из TogglTrack API при старте приложения
    private static let daysToLoad = 7

    // MARK: init/deinit
    init(
        togglAPI: TogglAPI,
        menuTimer: TimeEntryTimer,
        settings: AppSettings,
        pomodoroService: PomodoroService,
        targetDailyHours: Int = 0,
        targetWeeklyHours: Int = 0,
    ) {
        self.settings = settings
        self.pomodoroService = pomodoroService
        self.togglAPI = togglAPI
        self.menuTimer = menuTimer
        self.targetDailyHours = targetDailyHours
        self.targetWeeklyHours = targetWeeklyHours

        pomodoroService.bind(
            currentEntry: $currentEntry.eraseToAnyPublisher(),
            pomodoroMinutes: settings.pomodoroSizePublisher,
        )

        togglAPI.rateLimitSubject
            // переключаемся на главный поток (обязательно для UI)
            .receive(on: DispatchQueue.main)
            // подписываемся и получаем каждое новое значение в замыкании
            .sink { [weak self] newValue in
                self?.rateLimit = newValue
            }
            // сохраняем подписку в Set, чтобы она жила пока жив ViewModel
            .store(in: &cancellables)

        // Обновляем расчеты при смене суток
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recomputeStats() }
            .store(in: &cancellables)

        // Обновляем расчеты при активации (если спали в полночь)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recomputeStats() }
            .store(in: &cancellables)

        // Обновляем расчеты при пробуждении системы (на всякий случай)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recomputeStats() }
            .store(in: &cancellables)

        // Обрабатываем нажатие кнопки "Остановить запись" в уведомлении помидора
        NotificationService.shared.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .stopCurrentTimeEntry(let entryId):
                    // Убеждаемся, что в уведомлении указана текущая запись
                    guard self.currentEntry?.id == entryId else { return }
                    Task { await self.stopCurrentEntry() }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Entry management
    /// "Продолжает" указанный entry – фактически, создаётся новый в том же workspace, проекте и с тем же описанием.
    func continueEntry(from entry: TogglTimeEntry) async {
        do {
            let newEntry = try await togglAPI.createTimeEntry(
                workspaceId: entry.workspaceId,
                projectId: entry.projectId,
                description: entry.description,
            )
            if newEntry != nil {
                setCurrentEntry(newEntry)
            }
        } catch {
            handleError(error, context: "Ошибка при продолжении записи времени")
        }
    }

    /// Останавливает текущую запись времени.
    func stopCurrentEntry() async {
        guard let entry = currentEntry else { return }

        do {
            let stoppedEntry = try await togglAPI.stopCurrentTimeEntry(
                workspaceId: entry.workspaceId,
                timeEntryId: entry.id
            )
            setCurrentEntry(nil)

            // Добавляем завершенную запись времени и обновляем статистику
            if let stoppedEntry {
                latestEntries.insert(stoppedEntry, at: 0)
                recomputeStats()
            }
        } catch {
            handleError(error, context: "Ошибка при остановке записи времени")
        }
    }

    /// Устанавливает текущую активную запись времени и синхронизирует таймер меню.
    private func setCurrentEntry(_ entry: TogglTimeEntry?) {
        currentEntry = entry

        // Синхронизируем таймер меню
        if let startDate = entry?.startDate {
            menuTimer.start(from: startDate)
        } else {
            menuTimer.stop()
        }
    }

    // MARK: Data management
    /// Загружает необходимые данные из TogglTrackAPI, если они не были загружены ранее.
    /// Должно быть вызвано в .task соответствующего вида.
    func loadIfNeeded() async {
        // TODO: загружать мок-данные для превью
        // Не загружаем данные в режиме превью Xcode, чтобы не расходовать квоту TogglTrack API
        guard !ProcessInfo.isPreview else { return }
        guard !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        await loadUser()
        await loadCurrentEntry()
        await loadLatestEntries()
    }

    /// Загружает данные пользователя со всеми связанными данными, и составляет словарь соответствия
    /// id проекта -> данные проекта.
    private func loadUser() async {
        do {
            self.user = try await togglAPI.getMe()

            // Добавляем все проекты пользователя в словарь для поиска по id
            guard let projects = self.user?.projects else { return }
            for project in projects {
                self.projects[project.id] = project
            }
        } catch {
            handleError(error, context: "Ошибка при загрузке данных пользователя")
        }
    }

    /// Загружает текущую запись времени.
    private func loadCurrentEntry() async {
        do {
            let entry = try await togglAPI.getCurrentTimeEntry()
            setCurrentEntry(entry)
        } catch {
            handleError(error, context: "Ошибка при загрузке текущей записи времени")
        }
    }

    /// Загружает записи времени за последние daysToLoad дней из TogglTrack API.
    private func loadLatestEntries() async {
        let (start, end) = Formatters.dateRangeStrings(
            Calendar.current.dateRange(lastDays: TogglViewModel.daysToLoad)
        )

        do {
            latestEntries = try await togglAPI.getTimeEntries(
                startDate: start,
                endDate: end
            )
            latestUniqueEntries = latestEntries.uniqued { entry in
                UniqueTimeEntryKey(
                    description: entry.description,
                    projectId: entry.projectId
                )
            }

            // Вычисляем статистику по загруженным данным
            recomputeStats()
        } catch {
            handleError(error, context: "Ошибка при загрузке записей времени")
        }
    }

    /// Вычисляет статистику по времени на основе загруженных entries.
    private func recomputeStats() {
        // 1. Подготовка: настраиваем календарь один раз
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // Понедельник

        // 2. Вычисляем границы один раз
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            stats = TimeStats()  // Сброс при ошибке
            return
        }

        // 3. Один проход по массиву
        var todaySeconds = 0
        var weekSeconds = 0

        for entry in latestEntries {
            // Пропускаем запись с отрицательной длительностью (текущую)
            guard entry.duration > 0 else { continue }

            // Парсим дату один раз для каждого entry
            guard let entryDate = Formatters.isoParser.date(from: entry.start) else { continue }

            // Проверяем принадлежность к неделе
            if entryDate >= weekStart {
                weekSeconds += entry.duration

                // Если в этой неделе, проверяем — может это сегодня?
                if entryDate >= todayStart {
                    todaySeconds += entry.duration
                }
            }
        }

        // 4. Присваиваем результат один раз
        stats = TimeStats(todaySeconds: todaySeconds, weekSeconds: weekSeconds)
    }

    // MARK: Error handling
    /// Выводит системное уведомление с информацией об ошибке, и логирует её.
    private func handleError(_ error: Error, context: String) {
        NotificationService.shared.showError(message: "\(context): \(error.localizedDescription)")
        Log.viewModel.error("❌ \(context, privacy: .public): \(error, privacy: .public)")

        // Для наших кастомных ошибок API выводим подробности при наличии
        guard let apiError = error as? TogglAPIError else { return }
        if let reason = apiError.failureReason {
            Log.viewModel.error("⚠️ \(reason, privacy: .public)")
        }
    }
}
