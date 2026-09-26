import Foundation

extension Calendar {
    /// テストはタイムゾーンを固定して実行する
    nonisolated static let tokyo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }()
}

/// 東京時間で日時を作る
nonisolated func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    Calendar.tokyo.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}
