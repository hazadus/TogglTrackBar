import Foundation

enum Formatters {
    // TODO: Thread safety
    /// Парсер из ISO-строк вида "2026-01-11T09:50:06+00:00" в Date.
    static let isoParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Форматтер для даты в формате "yyyy-MM-dd".
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Форматтер для даты в формате "yyyy-MM-dd HH:mm".
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    /// Количество секунд, прошедших с момента, представленного строкой isoString, до текущего момента.
    static func elapsedSeconds(from isoString: String) -> Double? {
        // Почему таймзона "просто работает":
        //   Date — это момент во времени (секунды с 1970).
        //   Парсер читает +00:00 и корректно создаёт Date.
        //   При вычислении разницы обе даты уже в одной системе координат.
        guard let startDate = Formatters.isoParser.date(from: isoString) else { return nil }
        return elapsedSeconds(from: startDate)
    }

    /// Количество секунд от `startDate` до `now`.
    static func elapsedSeconds(from startDate: Date, now: Date = Date()) -> Double {
        max(0, now.timeIntervalSince(startDate))
    }

    /// Форматирует время прошедшее с момента isoString до текущего в строку "HH:MM:SS".
    static func elapsedTime(from isoString: String) -> String? {
        guard let seconds = elapsedSeconds(from: isoString) else { return nil }
        return secondsAsTime(from: seconds)
    }

    /// Форматирует время, прошедшее от `startDate` до `now`, в строку "HH:MM:SS".
    static func elapsedTime(from startDate: Date, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(startDate))
        return secondsAsTime(from: seconds)
    }

    /// Форматирует количество секунд в строку вида "HH:MM:SS".
    static func secondsAsTime(from totalSeconds: Double) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Форматирует пару дат и возвращает в виде строк формата "yyyy-MM-dd".
    static func dateRangeStrings(
        _ range: (start: Date, end: Date),
    ) -> (start: String, end: String) {
        let (start, end) = range
        return (
            start: Formatters.dateOnly.string(from: start),
            end: Formatters.dateOnly.string(from: end),
        )
    }
}
