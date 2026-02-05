import AppKit
import Combine
import Foundation

/// Управляет уведомлениями от таймера помидора.
///
/// Помидор – период сосредоточенной работы (то есть записи времени), по истечении которого
/// следует сделать перерыв. Обычно это 25 минут. Размер помидора (продолжительность в минутах) задаётся
/// пользователем в окне настроек приложения. По умолчанию размер помидора равен нулю – в таком
/// случае, пользователь не получает уведомлений о необходимости сделать перерыв в работе.
@MainActor
final class PomodoroService {
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    /// Ключ записи времени, для которой уже показали уведомление.
    ///
    /// Без защиты от повторных уведомлений, уведомление может прийти несколько раз для одной записи:
    /// - при wake/active;
    /// - если pomodoroMinutes изменён через настройки, но текущая запись времени та же.
    private var notifiedEntryKey: TimeEntryKey?
    /// Последние значения для пересчета при пробуждении системы
    private var lastEntry: TogglTimeEntry?
    private var lastPomodoroMinutes: Int = 0

    private let notificationService: NotificationService

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    /// Привязывает сервис к источникам данных и начинает отслеживать помидоры.
    func bind(
        currentEntry: AnyPublisher<TogglTimeEntry?, Never>,
        pomodoroMinutes: AnyPublisher<Int, Never>,
    ) {
        // Делаем метод идемпотентным
        timerCancellable?.cancel()
        timerCancellable = nil
        cancellables.removeAll()

        // При изменении любого из источников данных перепланируем таймер
        currentEntry
            .combineLatest(pomodoroMinutes.removeDuplicates())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry, minutes in
                self?.schedule(for: entry, pomodoroMinutes: minutes)
            }
            .store(in: &cancellables)

        // Пересчитываем при пробуждении системы или при активации приложения
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .merge(
                with: NotificationCenter.default.publisher(
                    for: NSApplication.didBecomeActiveNotification
                )
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.schedule(for: self.lastEntry, pomodoroMinutes: self.lastPomodoroMinutes)
            }
            .store(in: &cancellables)
    }

    /// Планирует уведомление для указанной записи времени.
    private func schedule(for entry: TogglTimeEntry?, pomodoroMinutes: Int) {
        timerCancellable?.cancel()
        timerCancellable = nil

        // Сохраняем для пересчета при пробуждении или активации приложения
        lastEntry = entry
        lastPomodoroMinutes = pomodoroMinutes

        // Проверяем: есть текущая запись времени, есть startDate, помидоры включены
        guard let entry,
            let startDate = entry.startDate,
            pomodoroMinutes > 0
        else {
            return
        }

        // Сбрасываем флаг, если по этой записи времени не было уведомления
        let currentKey = TimeEntryKey(id: entry.id, start: startDate)
        if notifiedEntryKey != currentKey {
            notifiedEntryKey = nil
        }

        // Вычисляем время до срабатывания таймера
        let deadline = startDate.addingTimeInterval(TimeInterval(pomodoroMinutes * 60))
        // TimeInterval это alias Double, значение представляет собой количество секунд
        let remainingSeconds = deadline.timeIntervalSince(Date())

        if remainingSeconds <= 0 {
            // Время помидора прошло – уведомляем пользователя сразу
            showNotification(
                entryId: entry.id,
                entryStart: startDate,
                pomodoroMinutes: pomodoroMinutes,
            )
        } else {
            // Планируем уведомление через remaining секунд
            timerCancellable = Just(())  // () – Void, нам не нужно передавать данные
                .delay(for: .seconds(remainingSeconds), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    self?.showNotification(
                        entryId: entry.id,
                        entryStart: startDate,
                        pomodoroMinutes: pomodoroMinutes,
                    )
                }
        }
    }

    /// Показывает уведомление о завершении помидора, если для указанной записи времени ранее
    /// не показывалось уведомление.
    private func showNotification(
        entryId: Int,
        entryStart: Date,
        pomodoroMinutes: Int,
    ) {
        let key = TimeEntryKey(id: entryId, start: entryStart)
        guard notifiedEntryKey != key else { return }

        notifiedEntryKey = key

        notificationService.show(
            title: "Таймер помидора 🍅",
            body: "\(pomodoroMinutes) мин. прошло – пора сделать перерыв!",
            categoryIdentifier: NotificationService.categoryPomodoro,
            userInfo: [NotificationService.keyEntryId: entryId],
        )
    }
}

/// Ключ для идентификации записей времени для защиты от повторных уведомлений.
private struct TimeEntryKey: Equatable {
    let id: Int
    let start: Date
}
