import Foundation

extension Calendar {
    /// Возвращает диапазон дат – от lastDays дней назад до завтра.
    func dateRange(lastDays: Int) -> (start: Date, end: Date) {
        let today = Date()
        let startDay = self.date(byAdding: .day, value: -lastDays, to: today)!
        let tomorrow = self.date(byAdding: .day, value: 1, to: today)!

        return (
            start: startDay,
            end: tomorrow,
        )
    }
}
