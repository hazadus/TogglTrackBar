import Foundation

/// Метаданные приложения из Bundle (Info.plist).
enum AppInfo {
    // Для группировки статических свойств в Swift идиоматично использовать enum без cases:
    // - Нельзя создать экземпляр — AppInfo() не скомпилируется
    // - Это сигнал: "здесь только статические члены, не храни состояние"

    // Почему computed properties, а не stored?
    // Оба варианта работают для Bundle (он не меняется в runtime). Computed property здесь — вопрос стиля: явно показывает, что значение "получается", а не "хранится".

    /// Bundle Identifier (например, "hazadus.TogglTrackBar").
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    /// Версия приложения — CFBundleShortVersionString (например, "1.2.0").
    /// Это "маркетинговая" версия, которую видят пользователи.
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "Unknown"
    }

    /// Номер сборки — CFBundleVersion (например, "42").
    /// Увеличивается с каждой сборкой.
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
}

