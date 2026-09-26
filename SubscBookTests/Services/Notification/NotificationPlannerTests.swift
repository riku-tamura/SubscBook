import Foundation
import Testing
@testable import SubscBook

@Suite("通知の予定（9章）")
struct NotificationPlannerTests {
    private let now = date(2026, 9, 26, 10)

    private func plan(
        _ subscriptions: [Subscription],
        isPremium: Bool = false,
        preferences: NotificationPreferences = NotificationPreferences(),
        now: Date? = nil
    ) -> [PlannedNotification] {
        NotificationPlanner.plan(
            subscriptions: subscriptions,
            isPremium: isPremium,
            preferences: preferences,
            now: now ?? self.now,
            calendar: .tokyo
        )
    }

    private func fireDates(_ notifications: [PlannedNotification], kind: PlannedNotification.Kind) -> [Date] {
        notifications.filter { $0.kind == kind }.compactMap {
            if case .once(let date) = $0.trigger { date } else { nil }
        }
    }

    @Test("支払日の前日 9:00。月額は3回先まで登録する")
    func monthlyPaymentReminders() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(name: "Netflix", price: 1590, nextPaymentDate: date(2026, 10, 15))

        let notifications = plan([subscription])

        #expect(fireDates(notifications, kind: .payment) == [date(2026, 10, 14, 9), date(2026, 11, 14, 9), date(2026, 12, 14, 9)])
        let first = try #require(notifications.first { $0.kind == .payment })
        #expect(first.title == "明日は「Netflix」の支払日です")
        #expect(first.body.contains("1,590円"))
        #expect(first.subscriptionID == subscription.id)
    }

    @Test("月末払いは基準日を保って前日に通知する")
    func monthEndReminders() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(nextPaymentDate: date(2027, 1, 31))

        let notifications = plan([subscription], now: date(2027, 1, 10))

        #expect(fireDates(notifications, kind: .payment) == [date(2027, 1, 30, 9), date(2027, 2, 27, 9), date(2027, 3, 30, 9)])
    }

    @Test("年額は次の1回だけ")
    func yearlyPaymentReminder() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(cycle: .yearly, nextPaymentDate: date(2027, 3, 1))

        #expect(fireDates(plan([subscription]), kind: .payment) == [date(2027, 2, 28, 9)])
    }

    @Test("過ぎた通知時刻は登録しない")
    func skipsPastFireDates() throws {
        let store = try TestStore()
        // 明日が支払日だが、今日の 9:00 は過ぎている
        let subscription = store.addSubscription(nextPaymentDate: date(2026, 9, 27))

        #expect(fireDates(plan([subscription]), kind: .payment) == [date(2026, 10, 26, 9), date(2026, 11, 26, 9)])
    }

    @Test("支払日が古いままでも、今日以降の支払日から計算する")
    func usesAdvancedPaymentDate() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(nextPaymentDate: date(2026, 7, 20))

        #expect(fireDates(plan([subscription]), kind: .payment).first == date(2026, 10, 19, 9))
    }

    @Test("解約済みは通知しない")
    func skipsCanceled() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(status: .canceled, canceledAt: date(2026, 9, 1))

        #expect(plan([subscription]).isEmpty)
    }

    @Test("トライアル終了の3日前・前日の通知はプラスのみ")
    func trialReminders() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(name: "Duolingo")
        subscription.setTrialEndDate(date(2026, 10, 5), calendar: .tokyo)

        #expect(fireDates(plan([subscription], isPremium: false), kind: .trial).isEmpty)

        let notifications = plan([subscription], isPremium: true).filter { $0.kind == .trial }
        #expect(fireDates(notifications, kind: .trial) == [date(2026, 10, 2, 9), date(2026, 10, 4, 9)])
        #expect(notifications.map(\.title) == [
            "「Duolingo」の無料トライアルがあと3日で終わります",
            "「Duolingo」の無料トライアルが明日で終わります",
        ])
    }

    @Test("トライアルの前日だけが残っている場合")
    func trialReminderOnlyDayBefore() throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        subscription.setTrialEndDate(date(2026, 9, 28), calendar: .tokyo)

        #expect(fireDates(plan([subscription], isPremium: true), kind: .trial) == [date(2026, 9, 27, 9)])
    }

    @Test("月次チェックインは毎月1日 20:00 に繰り返す。有効なサブスクがなければ登録しない")
    func checkInReminder() throws {
        let store = try TestStore()
        #expect(plan([]).isEmpty)

        let notifications = plan([store.addSubscription()])
        let checkIn = try #require(notifications.first { $0.kind == .checkIn })
        #expect(checkIn.trigger == .monthly(day: 1, hour: 20))
    }

    @Test("登録して1ヶ月たっていないサブスクしかない場合は、聞けるようになる月の1日だけに通知する")
    func checkInReminderForNewUser() throws {
        let store = try TestStore()
        // 9/26 に登録 → 10/1 は登録から1ヶ月未満なので聞かず、11/1 から聞く
        let subscription = store.addSubscription(createdAt: date(2026, 9, 26, 9))

        let checkIn = try #require(plan([subscription]).first { $0.kind == .checkIn })

        #expect(checkIn.trigger == .once(date(2026, 11, 1, 20)))
    }

    @Test("次の1日に聞けるサブスクがあれば、毎月の繰り返しにする")
    func checkInReminderRepeatsWhenEligible() throws {
        let store = try TestStore()
        // 8/30 に登録 → 10/1 には登録から1ヶ月たっている
        let subscription = store.addSubscription(createdAt: date(2026, 8, 30))

        let checkIn = try #require(plan([subscription]).first { $0.kind == .checkIn })

        #expect(checkIn.trigger == .monthly(day: 1, hour: 20))
    }

    @Test("設定でオフにした通知は登録しない")
    func respectsPreferences() throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        subscription.setTrialEndDate(date(2026, 10, 10), calendar: .tokyo)

        let paymentOff = plan([subscription], isPremium: true, preferences: .init(paymentReminder: false))
        #expect(Set(paymentOff.map(\.kind)) == [.trial, .checkIn])

        let allOff = plan(
            [subscription], isPremium: true,
            preferences: .init(paymentReminder: false, trialReminder: false, checkInReminder: false)
        )
        #expect(allOff.isEmpty)
    }

    @Test("上限64件を超える場合は直近の予定を優先する")
    func respectsLimit() throws {
        let store = try TestStore()
        let subscriptions = (1...30).map { day in
            store.addSubscription(name: "サブスク\(day)", nextPaymentDate: date(2026, 10, day))
        }

        let notifications = plan(subscriptions)

        #expect(notifications.count == NotificationPlanner.maxPendingRequests)
        #expect(notifications.filter { $0.kind == .checkIn }.count == 1)
        let kept = fireDates(notifications, kind: .payment)
        let all = fireDates(plan(subscriptions, preferences: .init(checkInReminder: false)), kind: .payment)
        // 登録されなかった予定は、登録された予定より後
        #expect(kept.max()! <= all.sorted()[kept.count])
    }

    @Test("識別子は重複しない")
    func uniqueIdentifiers() throws {
        let store = try TestStore()
        let subscriptions = (1...5).map { store.addSubscription(name: "\($0)", nextPaymentDate: date(2026, 10, $0)) }
        subscriptions[0].setTrialEndDate(date(2026, 10, 20), calendar: .tokyo)

        let identifiers = plan(subscriptions, isPremium: true).map(\.identifier)
        #expect(Set(identifiers).count == identifiers.count)
    }
}
