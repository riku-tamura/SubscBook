import Foundation
import SwiftData
import Testing
@testable import SubscBook

@Suite("Subscription / CheckIn モデル")
struct SubscriptionModelTests {
    @Test("enum アクセサは rawValue と相互変換する")
    func enumAccessors() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(category: .music, cycle: .yearly)
        #expect(subscription.category == .music)
        #expect(subscription.cycle == .yearly)
        #expect(subscription.status == .active)

        subscription.category = .cloud
        subscription.cycle = .monthly
        #expect(subscription.categoryRawValue == "cloud")
        #expect(subscription.cycleRawValue == "monthly")
    }

    @Test("解約すると status と解約日が記録される")
    func cancel() throws {
        let store = try TestStore()
        let subscription = store.addSubscription()

        subscription.cancel(at: date(2026, 9, 26))

        #expect(subscription.status == .canceled)
        #expect(!subscription.isActive)
        #expect(subscription.canceledAt == date(2026, 9, 26))
    }

    @Test("契約中に戻すと解約日を消し、過ぎた支払日を進める")
    func reactivate() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(nextPaymentDate: date(2026, 5, 31))
        subscription.cancel(at: date(2026, 5, 20))

        subscription.reactivate(now: date(2026, 9, 26), calendar: .tokyo)

        #expect(subscription.status == .active)
        #expect(subscription.canceledAt == nil)
        #expect(subscription.nextPaymentDate == date(2026, 9, 30))
    }

    @Test("activePredicate は有効なサブスクだけを取得する")
    func activePredicate() throws {
        let store = try TestStore()
        store.addSubscription(name: "有効")
        store.addSubscription(name: "解約済み", status: .canceled, canceledAt: .now)

        let fetched = try store.context.fetch(FetchDescriptor(predicate: Subscription.activePredicate))

        #expect(fetched.map(\.name) == ["有効"])
    }

    @Test("同じ月のチェックインは上書きする")
    func recordCheckInUpserts() throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        let month = YearMonth("2026-08")!

        subscription.recordCheckIn(for: month, used: true, at: date(2026, 9, 1))
        subscription.recordCheckIn(for: month, used: false, at: date(2026, 9, 2))
        subscription.recordCheckIn(for: month.previous, used: true, at: date(2026, 9, 2))

        #expect(subscription.checkIns.count == 2)
        #expect(subscription.checkIn(for: month)?.used == false)
        #expect(subscription.checkIn(for: month)?.answeredAt == date(2026, 9, 2))
        #expect(subscription.checkIn(for: month)?.subscription?.id == subscription.id)
    }

    @Test("サブスクを削除するとチェックインも削除される")
    func cascadeDelete() throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        subscription.recordCheckIn(for: YearMonth("2026-08")!, used: true)
        try store.context.save()
        #expect(try store.context.fetchCount(FetchDescriptor<CheckIn>()) == 1)

        store.context.delete(subscription)
        try store.context.save()

        #expect(try store.context.fetchCount(FetchDescriptor<CheckIn>()) == 0)
    }
}
