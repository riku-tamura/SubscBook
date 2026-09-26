import Foundation
import SwiftData
import Testing
@testable import SubscBook

@Suite("次回支払日の更新（5.2）")
struct PaymentDateCalculatorTests {
    private func advance(_ start: Date, _ cycle: BillingCycle, billingDay: Int, times: Int) -> [Date] {
        var current = start
        return (0..<times).map { _ in
            current = PaymentDateCalculator.paymentDate(
                after: current, cycle: cycle, billingDay: billingDay, calendar: .tokyo
            )
            return current
        }
    }

    @Test("月末日は元の日を保持する：1/31 → 2/28 → 3/31 → 4/30 → 5/31")
    func monthEndIsPreserved() {
        let dates = advance(date(2026, 1, 31), .monthly, billingDay: 31, times: 4)
        #expect(dates == [date(2026, 2, 28), date(2026, 3, 31), date(2026, 4, 30), date(2026, 5, 31)])
    }

    @Test("うるう年の2月は29日になる")
    func leapYearFebruary() {
        let dates = advance(date(2028, 1, 31), .monthly, billingDay: 31, times: 2)
        #expect(dates == [date(2028, 2, 29), date(2028, 3, 31)])
    }

    @Test("30日払いも2月をまたいで元に戻る")
    func day30() {
        let dates = advance(date(2027, 1, 30), .monthly, billingDay: 30, times: 2)
        #expect(dates == [date(2027, 2, 28), date(2027, 3, 30)])
    }

    @Test("年をまたぐ月額")
    func monthlyAcrossYear() {
        let dates = advance(date(2026, 12, 15), .monthly, billingDay: 15, times: 1)
        #expect(dates == [date(2027, 1, 15)])
    }

    @Test("年額の2/29はうるう年だけ29日になる")
    func yearlyLeapDay() {
        let dates = advance(date(2028, 2, 29), .yearly, billingDay: 29, times: 4)
        #expect(dates == [date(2029, 2, 28), date(2030, 2, 28), date(2031, 2, 28), date(2032, 2, 29)])
    }

    @Test("過去の支払日は今日以降になるまで進める", arguments: [
        // (支払日, 周期, 今日, 期待値)
        (date(2026, 6, 15), BillingCycle.monthly, date(2026, 9, 26, 10), date(2026, 10, 15)),
        (date(2026, 9, 25), BillingCycle.monthly, date(2026, 9, 26, 10), date(2026, 10, 25)),
        (date(2025, 3, 10), BillingCycle.yearly, date(2026, 9, 26, 10), date(2027, 3, 10)),
    ])
    func advancesPastDate(start: Date, cycle: BillingCycle, now: Date, expected: Date) {
        let billingDay = Calendar.tokyo.component(.day, from: start)
        let result = PaymentDateCalculator.advancedPaymentDate(
            from: start, cycle: cycle, billingDay: billingDay, now: now, calendar: .tokyo
        )
        #expect(result == expected)
    }

    @Test("今日・未来の支払日は進めない", arguments: [
        date(2026, 9, 26),
        date(2026, 12, 1),
    ])
    func keepsTodayAndFuture(start: Date) {
        let billingDay = Calendar.tokyo.component(.day, from: start)
        let result = PaymentDateCalculator.advancedPaymentDate(
            from: start, cycle: .monthly, billingDay: billingDay, now: date(2026, 9, 26, 23, 59), calendar: .tokyo
        )
        #expect(result == start)
    }

    @Test("サブスクの支払日を更新しても基準日（31日）を保持する")
    func refreshKeepsBillingDay() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(nextPaymentDate: date(2026, 1, 31))

        let firstUpdate = PaymentDateCalculator.refreshPaymentDates(
            of: [subscription], now: date(2026, 2, 10), calendar: .tokyo
        )
        #expect(firstUpdate.count == 1)
        #expect(subscription.nextPaymentDate == date(2026, 2, 28))
        #expect(subscription.billingDay == 31)

        PaymentDateCalculator.refreshPaymentDates(of: [subscription], now: date(2026, 3, 5), calendar: .tokyo)
        #expect(subscription.nextPaymentDate == date(2026, 3, 31))
    }

    @Test("解約済み・支払日が未来のサブスクは更新しない")
    func refreshSkipsCanceledAndFuture() throws {
        let store = try TestStore()
        let canceled = store.addSubscription(
            nextPaymentDate: date(2026, 5, 1), status: .canceled, canceledAt: date(2026, 4, 20)
        )
        let future = store.addSubscription(nextPaymentDate: date(2026, 10, 1))

        let updated = PaymentDateCalculator.refreshPaymentDates(
            of: [canceled, future], now: date(2026, 9, 26), calendar: .tokyo
        )

        #expect(updated.isEmpty)
        #expect(canceled.nextPaymentDate == date(2026, 5, 1))
        #expect(future.nextPaymentDate == date(2026, 10, 1))
    }

    @Test("ModelContext から有効なサブスクを取得して更新・保存する")
    func refreshInContext() throws {
        let store = try TestStore()
        let active = store.addSubscription(nextPaymentDate: date(2026, 8, 20))
        let canceled = store.addSubscription(
            nextPaymentDate: date(2026, 8, 20), status: .canceled, canceledAt: date(2026, 8, 1)
        )
        try store.context.save()

        let updated = try PaymentDateCalculator.refreshPaymentDates(
            in: store.context, now: date(2026, 9, 26), calendar: .tokyo
        )

        #expect(updated.map(\.id) == [active.id])
        #expect(active.nextPaymentDate == date(2026, 10, 20))
        #expect(canceled.nextPaymentDate == date(2026, 8, 20))
        #expect(!store.context.hasChanges)
    }

    @Test("登録時・支払日変更時に日付を0:00に正規化し、基準日を記録する")
    func normalizesAndRecordsBillingDay() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(nextPaymentDate: date(2026, 1, 31, 15, 30))
        #expect(subscription.nextPaymentDate == date(2026, 1, 31))
        #expect(subscription.billingDay == 31)

        subscription.setNextPaymentDate(date(2026, 3, 15, 8), calendar: .tokyo)
        #expect(subscription.nextPaymentDate == date(2026, 3, 15))
        #expect(subscription.billingDay == 15)
    }
}
