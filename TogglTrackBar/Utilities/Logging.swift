import Foundation
import os

enum Log {
    static let subsystem = Bundle.main.bundleIdentifier ?? "hazadus.TogglTrackBar"

    /// Категории логгеров по области функционала приложения.
    static let api = Logger(subsystem: subsystem, category: "api")
    static let viewModel = Logger(subsystem: subsystem, category: "viewModel")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
