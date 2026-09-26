import Foundation
import SwiftData

/// 次回支払日の更新（5.2）
enum PaymentDateCalculator {
    /// `date` から1周期進めた支払日を返す。
    /// 日付は `billingDay` を保ち、その月に存在しない場合は月末日にする（1/31 → 2/28 → 3/31）。
    nonisolated static func paymentDate(
        after date: Date,
        cycle: BillingCycle,
        billingDay: Int,
        calendar: Calendar = .current
    ) -> Date {
        let current = YearMonth(date: date, calendar: calendar)
        let target = current.adding(months: cycle.months)
        let firstOfTarget = target.startDate(calendar: calendar)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfTarget)!.count
        let day = min(max(billingDay, 1), daysInMonth)
        return calendar.date(from: DateComponents(year: target.year, month: target.month, day: day))!
    }

    /// 支払日が今日より前なら、今日以降になるまで周期分進める。今日の支払日はそのまま。
    nonisolated static func advancedPaymentDate(
        from date: Date,
        cycle: BillingCycle,
        billingDay: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Date {
        let today = calendar.startOfDay(for: now)
        var result = date
        while result < today {
            result = paymentDate(after: result, cycle: cycle, billingDay: billingDay, calendar: calendar)
        }
        return result
    }

    /// 有効なサブスクのうち、支払日が過ぎているものを更新する。起動時・フォアグラウンド復帰時に呼ぶ。
    /// - Returns: 支払日を更新したサブスク
    @discardableResult
    static func refreshPaymentDates(
        of subscriptions: [Subscription],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Subscription] {
        var updated: [Subscription] = []
        for subscription in subscriptions where subscription.isActive {
            let advanced = advancedPaymentDate(
                from: subscription.nextPaymentDate,
                cycle: subscription.cycle,
                billingDay: subscription.billingDay,
                now: now,
                calendar: calendar
            )
            if advanced != subscription.nextPaymentDate {
                subscription.nextPaymentDate = advanced
                updated.append(subscription)
            }
        }
        return updated
    }

    /// 保存済みの有効なサブスクを取得して支払日を更新する
    @discardableResult
    static func refreshPaymentDates(
        in context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> [Subscription] {
        let subscriptions = try context.fetch(FetchDescriptor(predicate: Subscription.activePredicate))
        let updated = refreshPaymentDates(of: subscriptions, now: now, calendar: calendar)
        // 保存に失敗しても取り消さない。進めた支払日は正しい値で、次に保存したときに保存されればよいため
        // （ユーザーに失敗を伝える操作ではないので、伝えた内容と保存された内容が食い違うこともない）。
        if !updated.isEmpty {
            try context.save()
        }
        return updated
    }
}
