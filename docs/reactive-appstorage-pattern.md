# Reactive @AppStorage Pattern

Паттерн для динамического применения настроек приложения без перезапуска через Combine publishers.

## Проблема

`@AppStorage` не предоставляет Combine publisher из коробки. Ручное создание publisher + didSet для каждого нового свойства не масштабируется.

## Решение

Единый `defaultsDidChange` publisher на `UserDefaults.didChangeNotification` + generic метод `publisher(_:)` с KeyPath:

```swift
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("pomodoroSize") var pomodoroSize: Int = 0
    @AppStorage("targetDailyHours") var targetDailyHours: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var defaultsDidChange: AnyPublisher<Void, Never> = {
        NotificationCenter.default.publisher(
            for: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
        .map { _ in () }
        .receive(on: RunLoop.main)
        .share()  // одна подписка для всех потребителей
        .eraseToAnyPublisher()
    }()
    
    init() {
        defaultsDidChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    func publisher<Value: Equatable>(
        _ keyPath: KeyPath<AppSettings, Value>
    ) -> AnyPublisher<Value, Never> {
        defaultsDidChange
            .map { [weak self] in
                guard let self else { fatalError("AppSettings deallocated") }
                return self[keyPath: keyPath]
            }
            .prepend(self[keyPath: keyPath])  // эмитим текущее значение сразу
            .removeDuplicates()                // фильтруем повторы
            .eraseToAnyPublisher()
    }
}
```

## Использование в ViewModel

```swift
settings.publisher(\.targetDailyHours)
    .sink { [weak self] value in
        self?.targetDailyHours = value
        self?.recomputeStats()
    }
    .store(in: &cancellables)
```

## Ключевые моменты

- `lazy var` — отложенная инициализация до первого использования
- `.share()` — одна подписка на NotificationCenter для всех потребителей
- `.prepend()` — подписчик получает текущее значение сразу при подписке
- `.removeDuplicates()` — фильтрует срабатывания, когда изменились другие ключи UserDefaults
- `Equatable` constraint — обязателен для `removeDuplicates()`

## Преимущества

- Добавление нового свойства = только `@AppStorage("key")`, без дополнительного boilerplate
- Инкапсуляция: потребители не знают про UserDefaults
- Типобезопасность через KeyPath
