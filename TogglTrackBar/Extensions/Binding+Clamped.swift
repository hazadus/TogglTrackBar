import SwiftUI

extension Binding where Value: Comparable {
    /// Создаёт новый Binding, который ограничивает записываемое значение снизу.
    func clamped(min minValue: Value) -> Binding<Value> {
        Binding<Value>(
            get: { self.wrappedValue },
            // Swift - модуль, в котором живут стандартные функции языка.
            // Указано здесь, потому что иначе компилятор ищет max внутри Binding,
            // не находит и выдаёт ошибку.
            set: { self.wrappedValue = Swift.max($0, minValue) }
        )
    }
}
