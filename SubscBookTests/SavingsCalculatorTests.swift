import Foundation
import Testing
@testable import SubscBook

@Suite("節約額（5.5）")
struct SavingsCalculatorTests {
    @Test("年間節約額は解約済みの1年あたりの支払額の合計")
    func annualSavings() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(price: 980, status: .canceled, canceledAt: date(2026, 8, 1)),
            store.addSubscription(price: 10000, cycle: .yearly, status: .canceled, canceledAt: date(2026, 8, 1)),
            store.addSubscription(price: 1490),
        ]

        #expect(SavingsCalculator.annualSavings(of: subscriptions) == 980 * 12 + 10000)
    }

    @Test("節約累計は解約日からの満了月数 × 月額換算", arguments: [
        (date(2026, 9, 14, 23), 2000),  // 6/15 → 9/14 は2ヶ月
        (date(2026, 9, 15, 8), 3000),   // 6/15 → 9/15 で3ヶ月（時刻は無視）
        (date(2026, 6, 15, 23), 0),     // 解約当日
        (date(2026, 6, 1), 0),          // 解約日より前
    ])
    func realizedSavings(now: Date, expected: Int) throws {
        let store = try TestStore()
        let subscription = store.addSubscription(price: 1000, status: .canceled, canceledAt: date(2026, 6, 15, 10))

        #expect(SavingsCalculator.realizedSavings(of: [subscription], now: now, calendar: .tokyo) == expected)
    }

    @Test("節約累計は解約済みのみ、複数件を合計する")
    func realizedSavingsSum() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(price: 1000, status: .canceled, canceledAt: date(2026, 6, 15)),
            store.addSubscription(price: 12000, cycle: .yearly, status: .canceled, canceledAt: date(2026, 8, 1)),
            store.addSubscription(price: 5000),
            // 解約日がないデータは0として扱う
            store.addSubscription(price: 3000, status: .canceled, canceledAt: nil),
        ]

        let total = SavingsCalculator.realizedSavings(of: subscriptions, now: date(2026, 9, 26), calendar: .tokyo)

        #expect(total == 3 * 1000 + 1 * 1000)
    }

    @Test("満了月数の数え方", arguments: [
        (date(2026, 1, 15), date(2026, 2, 14), 0),
        (date(2026, 1, 15), date(2026, 2, 15), 1),
        (date(2026, 1, 15), date(2027, 1, 15), 12),
        (date(2026, 3, 1), date(2026, 2, 1), 0),
    ])
    func elapsedFullMonths(from: Date, to: Date, expected: Int) {
        #expect(SavingsCalculator.elapsedFullMonths(from: from, to: to, calendar: .tokyo) == expected)
    }
}
