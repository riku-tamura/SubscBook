import Foundation
import Testing
@testable import SubWatch

@Suite("YearMonth")
struct YearMonthTests {
    @Test("\"yyyy-MM\" 形式で相互変換する")
    func keyRoundTrip() {
        let month = YearMonth(year: 2026, month: 9)
        #expect(month.key == "2026-09")
        #expect(YearMonth("2026-09") == month)
    }

    @Test("不正な文字列は nil", arguments: ["2026-13", "2026-00", "2026-9", "26-09", "2026/09", "abcd-ef", "2026-09-01", ""])
    func invalidKey(key: String) {
        #expect(YearMonth(key) == nil)
    }

    @Test("月の加減算は年をまたぐ")
    func arithmetic() {
        #expect(YearMonth(year: 2026, month: 1).previous == YearMonth(year: 2025, month: 12))
        #expect(YearMonth(year: 2026, month: 12).next == YearMonth(year: 2027, month: 1))
        #expect(YearMonth(year: 2026, month: 1).adding(months: -13) == YearMonth(year: 2024, month: 12))
        #expect(YearMonth(year: 2026, month: 0) == YearMonth(year: 2025, month: 12))
        #expect(YearMonth(year: 2026, month: 13) == YearMonth(year: 2027, month: 1))
    }

    @Test("日付から生成する（カレンダーのタイムゾーンに従う）")
    func fromDate() {
        #expect(YearMonth(date: date(2026, 9, 30, 23, 59), calendar: .tokyo).key == "2026-09")
        #expect(YearMonth(date: date(2026, 10, 1), calendar: .tokyo).key == "2026-10")
        #expect(YearMonth(year: 2026, month: 10).startDate(calendar: .tokyo) == date(2026, 10, 1))
    }

    @Test("順序比較")
    func comparable() {
        #expect(YearMonth(year: 2025, month: 12) < YearMonth(year: 2026, month: 1))
        #expect(YearMonth(year: 2026, month: 2) > YearMonth(year: 2026, month: 1))
    }
}
