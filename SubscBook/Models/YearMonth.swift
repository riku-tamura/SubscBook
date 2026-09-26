import Foundation

/// 年月を表す値型。`CheckIn.month` に保存する "2026-09" 形式の文字列と相互変換する。
nonisolated struct YearMonth: Hashable, Comparable, Sendable, CustomStringConvertible {
    let year: Int
    /// 1...12
    let month: Int

    init(year: Int, month: Int) {
        // month が範囲外でも年をまたいで正規化する（例：2026年13月 → 2027年1月）
        let (quotient, remainder) = (year * 12 + (month - 1)).quotientAndRemainder(dividingBy: 12)
        self.year = remainder < 0 ? quotient - 1 : quotient
        self.month = (remainder < 0 ? remainder + 12 : remainder) + 1
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month], from: date)
        self.init(year: components.year!, month: components.month!)
    }

    /// "2026-09" 形式の文字列から生成する。形式が不正な場合は nil。
    init?(_ key: String) {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2,
              parts[0].count == 4, parts[1].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]),
              (1...12).contains(month)
        else { return nil }
        self.year = year
        self.month = month
    }

    /// "2026-09" 形式
    var key: String {
        String(format: "%04d-%02d", year, month)
    }

    var description: String { key }

    var previous: YearMonth { adding(months: -1) }

    var next: YearMonth { adding(months: 1) }

    func adding(months: Int) -> YearMonth {
        YearMonth(year: year, month: month + months)
    }

    /// その月の1日 0:00
    func startDate(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}
