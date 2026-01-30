import Foundation

extension ProcessInfo {
    static var isPreview: Bool {
        /// Приложение запущено в Xcode в preview-режиме (для рендеринга canvas).
        processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
