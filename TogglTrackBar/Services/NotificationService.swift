import os
import UserNotifications

/// Сервис для вывода системных уведомлений.
final class NotificationService {
    static let shared = NotificationService()  // Singleton pattern

    private init() {}  // Приватный init запрещает создание других экземпляров

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
    private func show(title: String, body: String, sound: UNNotificationSound?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
