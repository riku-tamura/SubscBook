import Foundation

extension Locale {
    /// 表示は日本語のみ（MVP）
    nonisolated static let japanese = Locale(identifier: "ja_JP")
}

extension Int {
    /// "1,490円"
    nonisolated var yenText: String {
        "\(formatted(.number.locale(.japanese)))円"
    }
}

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

extension YearMonth {
    /// "8月"
    nonisolated var monthText: String { "\(month)月" }

    /// "2026年8月"
    nonisolated var fullText: String { "\(year)年\(month)月" }
}

extension Subscription {
    /// "1,490円/月"
    var priceText: String {
        "\(price.yenText)/\(cycle.unitLabel)"
    }

    /// VoiceOver 用の金額表現（"1,490円、毎月"）
    var priceAccessibilityText: String {
        "\(price.yenText)、\(cycle.displayName)"
    }
}
