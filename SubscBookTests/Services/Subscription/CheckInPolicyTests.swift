import Foundation
import SwiftData
import Testing
@testable import SubscBook

@Suite("月次チェックイン（5.6）")
struct CheckInPolicyTests {
    @Test("対象月は前月", arguments: [
        (date(2026, 9, 26), "2026-08"),
        (date(2026, 9, 1), "2026-08"),
        (date(2026, 1, 1), "2025-12"),
    ])
    func targetMonth(now: Date, expected: String) {
        #expect(CheckInPolicy.targetMonth(now: now, calendar: .tokyo).key == expected)
    }

    @Test("今日時点で登録から1ヶ月以上経っていれば対象（日単位で判定）", arguments: [
        (date(2026, 8, 26, 23), true),
        (date(2026, 8, 25), true),
        (date(2026, 8, 27), false),
        (date(2026, 9, 26), false),
    ])
    func eligibility(createdAt: Date, expected: Bool) throws {
        let store = try TestStore()
        let subscription = store.addSubscription(createdAt: createdAt)

        #expect(CheckInPolicy.isEligible(subscription, now: date(2026, 9, 26, 0, 30), calendar: .tokyo) == expected)
    }

    @Test("解約済みは対象外")
    func canceledIsNotEligible() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(status: .canceled, canceledAt: date(2026, 9, 1), createdAt: date(2026, 1, 1))

        #expect(!CheckInPolicy.isEligible(subscription, now: date(2026, 9, 26), calendar: .tokyo))
    }

    @Test("前月分が未回答の対象サブスクを抽出する")
    func pendingSubscriptions() throws {
        let store = try TestStore()
        store.addSubscription(name: "未回答")
        let answered = store.addSubscription(name: "回答済み")
        answered.recordCheckIn(for: YearMonth("2026-08")!, used: true)
        let answeredOlderOnly = store.addSubscription(name: "前々月のみ回答")
        answeredOlderOnly.recordCheckIn(for: YearMonth("2026-07")!, used: false)
        store.addSubscription(name: "登録したばかり", createdAt: date(2026, 9, 20))
        store.addSubscription(name: "解約済み", status: .canceled, canceledAt: date(2026, 9, 1))

        let pending = CheckInPolicy.pendingSubscriptions(
            in: try store.context.fetch(.init()), now: date(2026, 9, 26), calendar: .tokyo
        )

        #expect(Set(pending.map(\.name)) == ["未回答", "前々月のみ回答"])
    }

    @Test("バナー表示の判定")
    func needsCheckIn() throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        let now = date(2026, 9, 26)

        #expect(CheckInPolicy.needsCheckIn([subscription], now: now, calendar: .tokyo))

        subscription.recordCheckIn(for: YearMonth("2026-08")!, used: false)
        #expect(!CheckInPolicy.needsCheckIn([subscription], now: now, calendar: .tokyo))
        #expect(!CheckInPolicy.needsCheckIn([], now: now, calendar: .tokyo))
    }
}
