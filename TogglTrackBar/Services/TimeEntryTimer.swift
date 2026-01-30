import Combine
import Foundation

/// Таймер для отслеживания продолжительности записи времени.
///
/// Не взаимодействует со слоем данных (models), поэтому отнесён в сервисный слой,
/// а не к ViewModels.
@MainActor
final class TimeEntryTimer: ObservableObject {
    /// Текущее время — обновляется каждую секунду, пока таймер запущен.
    /// Views подписываются на это свойство для обновления.
    @Published private(set) var tick = Date()

    /// Дата начала текущей записи времени.
    private(set) var startDate: Date?

    private var cancellable: AnyCancellable?

    deinit {
        cancellable?.cancel()
    }

    /// Время, прошедшее с начала записи, в виде строки "HH:MM:SS".
    var elapsedTimeText: String? {
        guard let startDate else { return nil }
        return Formatters.elapsedTime(from: startDate, now: tick)
    }

    /// Количество секунд, прошедших с начала записи.
    var elapsedSeconds: Int {
        guard let startDate else { return 0 }
        return max(0, Int(tick.timeIntervalSince(startDate)))
    }

    /// Запускает таймер с указанной даты начала.
    func start(from date: Date) {
        startDate = date
        tick = Date()

        guard cancellable == nil else { return }

        cancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] date in
                self?.tick = date
            }
    }

    /// Останавливает таймер.
    func stop() {
        cancellable?.cancel()
        cancellable = nil
        startDate = nil
    }
}
