import Foundation
import Testing
@testable import SubscBook

@Suite("ホームの集計")
struct HomeSummaryTests {
    @Test("合計・件数・直近3件の支払い・解約候補・チェックイン要否")
    func summary() throws {
        let store = try TestStore()
        let unused = store.addSubscription(name: "未使用", price: 1000, nextPaymentDate: date(2026, 10, 20))
        unused.recordCheckIn(for: YearMonth("2026-07")!, used: false)
        unused.recordCheckIn(for: YearMonth("2026-08")!, used: false)
        let subscriptions = [
            unused,
            store.addSubscription(name: "1番目", price: 500, nextPaymentDate: date(2026, 9, 27)),
            store.addSubscription(name: "2番目", price: 12000, cycle: .yearly, nextPaymentDate: date(2026, 9, 30)),
            store.addSubscription(name: "3番目", price: 300, nextPaymentDate: date(2026, 10, 2)),
            store.addSubscription(name: "解約済み", price: 9999, nextPaymentDate: date(2026, 9, 26), status: .canceled, canceledAt: date(2026, 9, 1)),
        ]

        let summary = HomeSummary(subscriptions: subscriptions, now: date(2026, 9, 26), calendar: .tokyo)

        #expect(summary.monthlyTotal == 1000 + 500 + 1000 + 300)
        #expect(summary.annualTotal == 12000 + 6000 + 12000 + 3600)
        #expect(summary.activeCount == 4)
        #expect(summary.upcomingPayments.map(\.name) == ["1番目", "2番目", "3番目"])
        #expect(summary.cancelSuggestions.map(\.subscription.name) == ["未使用"])
        #expect(summary.needsCheckIn)
    }
}
