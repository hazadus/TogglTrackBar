import Combine
import SwiftUI

/// Обёртка для наблюдения за изменениями настроек приложения.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("apiKey") var apiKey: String = ""
    @AppStorage("targetDailyHours") var targetDailyHours: Int = 0
    @AppStorage("targetWeeklyHours") var targetWeeklyHours: Int = 0
    @AppStorage("pomodoroSize") var pomodoroSize: Int = 0

    private var cancellables = Set<AnyCancellable>()

    /// Единый паблишер изменений UserDefaults – срабатывает при любом изменении.
    ///
    /// Ретранслирует события изменений настроек приложения в `UserDefaults` своим подписчикам,
    /// сохраняя инкапсуляцию настроек в одном месте.
    private lazy var defaultsDidChange: AnyPublisher<Void, Never> = {
        // lazy обеспечит вызов замыкания только при первом обращении к переменной в init().
        NotificationCenter.default.publisher(
            for: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
        )
        .map { _ in () }  // пропускаем значение Notification, нам важен сам факт изменения
        .receive(on: RunLoop.main)
        .share()  // обеспечивает одну копию паблишера для всех подписчиков
        .eraseToAnyPublisher()
    }()

    init() {
        // Ретранслируем события изменения настроек своим подписчикам
        defaultsDidChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    /// Возвращает паблишер для любого `@AppStorage` свойства по `KeyPath`.
    /// Эмитит текущее значение сразу, затем при каждом изменении.
    func publisher<Value: Equatable>(  // generic - Value может быть любым типом, который умеет сравниваться
        _ keyPath: KeyPath<AppSettings, Value>  // типобезопасный путь к свойству типа Value
    ) -> AnyPublisher<Value, Never> {  // возвращает паблишер того же типа, что и свойство Value
        // Берём за основу паблишер, который эмити Void при любом изменении UserDefaults
        defaultsDidChange
            .map { [weak self] in
                guard let self else { fatalError("AppSettings deallocated") }
                // Читаем текущее значение выбранного через keyPath свойства
                return self[keyPath: keyPath]
            }
            .prepend(self[keyPath: keyPath])  // эмитим текущее значение сразу при подписке
            // didChangeNotification срабатывает на любое изменение UserDefaults.
            // Эмитим только если изменилось значение, на которое подписан подписчик:
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
