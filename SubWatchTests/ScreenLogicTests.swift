import Foundation
import Testing
@testable import SubWatch

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

@Suite("無料プランの制限")
struct FreePlanTests {
    @Test("無料は有効なサブスク5件まで、プラスは無制限", arguments: [
        (0, false, true),
        (4, false, true),
        (5, false, false),
        (5, true, true),
        (100, true, true),
    ])
    func canAdd(activeCount: Int, isPremium: Bool, expected: Bool) {
        #expect(FreePlan.canAddSubscription(activeCount: activeCount, isPremium: isPremium) == expected)
    }

    @Test("上限に達しているとペイウォール、そうでなければ登録画面を開く")
    func routerRequestsPaywallAtLimit() {
        let router = AppRouter()
        router.requestNewSubscription(activeCount: 4, isPremium: false)
        #expect(router.subscriptionForm?.id == "add")
        #expect(router.paywall == nil)

        router.subscriptionForm = nil
        router.requestNewSubscription(activeCount: 5, isPremium: false)
        #expect(router.subscriptionForm == nil)
        #expect(router.paywall == .subscriptionLimit)
    }
}
