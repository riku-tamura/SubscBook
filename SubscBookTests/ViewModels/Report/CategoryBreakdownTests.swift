import Foundation
import Testing
@testable import SubscBook

@Suite("カテゴリ別の集計")
struct CategoryBreakdownTests {
    @Test("有効なサブスクをカテゴリの定義順に集計し、割合の合計は1")
    func slices() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(category: .music, price: 1000),
            store.addSubscription(category: .video, price: 1500),
            store.addSubscription(category: .video, price: 500),
            store.addSubscription(category: .cloud, price: 12000, cycle: .yearly),
            store.addSubscription(category: .news, price: 3000, status: .canceled, canceledAt: .now),
        ]

        let breakdown = CategoryBreakdown(subscriptions: subscriptions)
        let slices = breakdown.slices

        #expect(slices.map(\.category) == [.video, .music, .cloud])
        #expect(slices.map(\.monthlyTotal) == [2000, 1000, 1000])
        #expect(slices.first?.count == 2)
        #expect(abs(slices.reduce(0) { $0 + $1.share } - 1) < 0.0001)
        #expect(breakdown.monthlyTotal == 4000)
        #expect(CategoryBreakdown(subscriptions: []).isEmpty)
    }
}
