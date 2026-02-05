import Combine
import os
import UserNotifications

/// Сервис для вывода системных уведомлений.
final class NotificationService: NSObject {
    static let shared = NotificationService()  // Singleton pattern

    // Идентификаторы уведомлений
    static let categoryPomodoro = "POMODORO_FINISHED"
    static let actionStopTimeEntry = "STOP_CURRENT_TIME_ENTRY"
    static let keyEntryId = "entryId"

    /// События для actionable-уведомлений.
    ///
    /// Можно отправить событие с данными:
    /// ```swift
    /// actions.send(.stopCurrentEntry(entryId: 123))
    /// ```
    ///
    /// Получатель сможет извлечь данные, например:
    /// ```swift
    /// if case .stopCurrentEntry(let entryId) = action {
    ///     print("ID: \(entryId)")
    /// }
    /// ```
    enum Action {
        case stopCurrentTimeEntry(entryId: Int)
    }

    /// Паблишер для публикации событий для подписчиков и подписки на них извне.
    let actions = PassthroughSubject<Action, Never>()

    // Приватный init запрещает создание других экземпляров
    private override init() { super.init() }

    /// Настраивает сервис: регистрирует категории уведомлений и назначает delegate.
    /// Вызывать при старте приложения, до показа уведомлений.
    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Создаём кнопку действия – остановка записи времени
        let stopAction = UNNotificationAction(
            identifier: Self.actionStopTimeEntry,
            title: "Остановить запись",
            options: []
        )

        // Создаём категорию уведомления с кнопкой действия
        let pomodoroCategory = UNNotificationCategory(
            identifier: Self.categoryPomodoro,
            actions: [stopAction],
            intentIdentifiers: [],
            options: [],
        )

        // Регистрируем категорию
        center.setNotificationCategories([pomodoroCategory])
    }

    /// Запрашивает у пользователя разрешение на отображение системных уведомлений.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { _, error in
            if let error = error {
                Log.ui.error("❌ Ошибка авторизации уведомлений: \(error, privacy: .public)")
            }
        }
    }

    /// Выводит системное уведомление об ошибке.
    func showError(title: String = "Ошибка", message: String) {
        show(title: title, body: message, sound: .default)
    }

    /// Выводит системное уведомление об успешной операции.
    func showSuccess(title: String = "Готово", message: String) {
        show(title: title, body: message, sound: .default)
    }

    /// Выводит системное уведомление с указанными параметрами.
    func show(
        title: String,
        body: String,
        sound: UNNotificationSound? = .default,
        categoryIdentifier: String? = nil,
        userInfo: [AnyHashable: Any] = [:],
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.userInfo = userInfo

        if let categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// Определяем делегата как расширение класса, чтобы не "раздувать" его и
// логически сгруппировать код
extension NotificationService: UNUserNotificationCenterDelegate {
    /// Вызывается перед показом уведомления, когда приложение активно.
    /// Без этого метода уведомления могут не отображаться при активном приложении.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void,
    ) {
        completionHandler([.banner, .sound])
    }

    /// Вызывается при нажатии на кнопку действия в уведомлении.
    ///
    /// Используем именно эту сигнатуру метода из протокола, так как она вызывается после
    /// взаимодействия пользователя с уведомлением (отсюда `didReceive`).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void,
    ) {
        defer { completionHandler() }

        guard response.actionIdentifier == Self.actionStopTimeEntry else { return }

        // Получаем кастомные данные, связанные с уведомлением
        let userInfo = response.notification.request.content.userInfo
        guard let entryId = entryIdToInt(userInfo: userInfo) else { return }

        // Публикуем событие на главном потоке (для исключения проблем с обновлением UI)
        DispatchQueue.main.async { [self] in
            self.actions.send(.stopCurrentTimeEntry(entryId: entryId))
        }
    }

    /// Пробует привести `entryId`  к `Int` разными способами, для надежности.
    ///
    /// Значение `entryId` может прийти как `Int` или `NSNumber`, нужно обработать оба случая.
    private func entryIdToInt(userInfo: [AnyHashable: Any]) -> Int? {
        // Получаем "сырое" значение любого типа
        guard let raw = userInfo[Self.keyEntryId] else { return nil }

        var entryId: Int?
        if let value = raw as? Int {
            entryId = value
        } else if let value = raw as? NSNumber {
            entryId = value.intValue
        }

        return entryId
    }
}
