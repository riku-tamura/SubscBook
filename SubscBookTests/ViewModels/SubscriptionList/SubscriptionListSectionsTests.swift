import Foundation
import Testing
@testable import SubscBook

@Suite("一覧の並び替え")
struct SubscriptionListSectionsTests {
    private func makeSubscriptions(_ store: TestStore) -> [Subscription] {
        [
            store.addSubscription(name: "B音楽", category: .music, price: 980, nextPaymentDate: date(2026, 10, 5)),
            store.addSubscription(name: "A動画", category: .video, price: 1490, nextPaymentDate: date(2026, 10, 20)),
            store.addSubscription(name: "C年額", category: .cloud, price: 24000, cycle: .yearly, nextPaymentDate: date(2026, 10, 1)),
            store.addSubscription(name: "D動画", category: .video, price: 500, nextPaymentDate: date(2026, 10, 3)),
            store.addSubscription(name: "解約1", status: .canceled, canceledAt: date(2026, 8, 1)),
            store.addSubscription(name: "解約2", status: .canceled, canceledAt: date(2026, 9, 1)),
        ]
    }

    @Test("支払日順", arguments: [
        (SubscriptionSortOrder.paymentDate, ["C年額", "D動画", "B音楽", "A動画"]),
        // 月額換算で比べる（年額24,000円 → 2,000円）
        (SubscriptionSortOrder.price, ["C年額", "A動画", "B音楽", "D動画"]),
        (SubscriptionSortOrder.category, ["D動画", "A動画", "B音楽", "C年額"]),
    ])
    func sortOrders(order: SubscriptionSortOrder, expected: [String]) throws {
        let store = try TestStore()
        let sections = SubscriptionListSections(subscriptions: makeSubscriptions(store), sortOrder: order)
        #expect(sections.active.map(\.name) == expected)
    }

    @Test("解約済みは別セクションで、解約日の新しい順")
    func canceledSection() throws {
        let store = try TestStore()
        let sections = SubscriptionListSections(subscriptions: makeSubscriptions(store), sortOrder: .paymentDate)
        #expect(sections.canceled.map(\.name) == ["解約2", "解約1"])
    }
}
