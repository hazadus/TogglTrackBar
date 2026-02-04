import Combine
import SwiftUI

/// Обёртка для наблюдения за изменениями настроек приложения.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("targetDailyHours") var targetDailyHours: Int = 0
    @AppStorage("targetWeeklyHours") var targetWeeklyHours: Int = 0
    @AppStorage("pomodoroSize") var pomodoroSize: Int = 0

    /// Publisher для pomodoroSize (AppStorage не даёт publisher напрямую)
    var pomodoroSizePublisher: AnyPublisher<Int, Never> {
        UserDefaults.standard.publisher(for: \.pomodoroSize)
            .eraseToAnyPublisher()
    }
}

extension UserDefaults {
    @objc dynamic var pomodoroSize: Int {
        integer(forKey: "pomodoroSize")
    }
}
