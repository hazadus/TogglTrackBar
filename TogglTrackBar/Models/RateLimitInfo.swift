import Foundation

/// Содержит информацию о TogglTrack API rate limits.
struct RateLimitInfo: Equatable {
    var limit: Int = 30
    var remaining: Int?
    var resetAt: Date?
    var lastUpdatedAt: Date = .now

    /// Считаем квоту низкой, если осталось <= 30%.
    var isLow: Bool {
        guard let remaining else { return false }
        return Double(remaining) / Double(limit) <= 0.3
    }
}
