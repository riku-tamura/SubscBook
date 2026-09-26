import Foundation
import Testing
@testable import SubscBook

@Suite("節約レポート")
struct ReportTests {
    @Test("年間節約額・節約累計・解約件数をまとめる")
    func savingsSummary() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(price: 980, status: .canceled, canceledAt: date(2026, 6, 20)),
            store.addSubscription(price: 12000, cycle: .yearly, status: .canceled, canceledAt: date(2026, 8, 17)),
            store.addSubscription(price: 1490),
        ]

        let summary = SavingsSummary(subscriptions: subscriptions, now: date(2026, 9, 26), calendar: .tokyo)

        #expect(summary.annualSavings == 980 * 12 + 12000)
        #expect(summary.realizedSavings == 3 * 980 + 1 * 1000)
        #expect(summary.canceledCount == 2)
        #expect(summary.hasSavings)
        #expect(!SavingsSummary(subscriptions: [], now: date(2026, 9, 26), calendar: .tokyo).hasSavings)
    }

    @Test("共有用の画像を作れる")
    func rendersShareImage() {
        let summary = SavingsSummary(annualSavings: 24_072, realizedSavings: 3_966, canceledCount: 2)
        #expect(SavingsShareCard.render(savings: summary) != nil)
    }
}
