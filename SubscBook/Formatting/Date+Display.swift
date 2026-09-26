import Foundation

extension Date {
    /// "10月15日(木)"
    nonisolated var monthDayWeekdayText: String {
        formatted(.dateTime.month().day().weekday().locale(.japanese))
    }

    /// "2026年10月15日"
    nonisolated var fullDateText: String {
        formatted(.dateTime.year().month().day().locale(.japanese))
    }

    /// 今日から見た日数の表現（"今日" / "明日" / "あと3日"）
    func relativeDayText(now: Date = .now, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: self)
        ).day ?? 0
        switch days {
        case ..<0: return "\(-days)日前"
        case 0: return "今日"
        case 1: return "明日"
        default: return "あと\(days)日"
        }
    }
}
