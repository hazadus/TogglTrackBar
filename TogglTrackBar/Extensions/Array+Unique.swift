import Foundation

extension Array {
    /// Возвращает массив с уникальными элементами по заданному ключу.
    /// Сохраняет порядок, оставляет первый встреченный элемент.
    func uniqued<KeyType: Hashable>(by keyPath: (Element) -> KeyType) -> [Element] {
        var seen = Set<KeyType>()
        return filter { element in seen.insert(keyPath(element)).inserted }
    }
}
