import Foundation

/// 月次チェックインの対象判定（5.6）
enum CheckInPolicy {
    /// チェックインの対象月（今日から見た前月）
    nonisolated static func targetMonth(now: Date = .now, calendar: Calendar = .current) -> YearMonth {
        YearMonth(date: now, calendar: calendar).previous
    }

    /// チェックインの対象になるサブスクか。有効かつ、今日時点で登録から1ヶ月以上経っていること。
    static func isEligible(
        _ subscription: Subscription,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard subscription.isActive else { return false }
        let registeredDay = calendar.startOfDay(for: subscription.createdAt)
        guard let oneMonthLater = calendar.date(byAdding: .month, value: 1, to: registeredDay) else {
            return false
        }
        return oneMonthLater <= calendar.startOfDay(for: now)
    }

    /// 前月分のチェックインが未回答のサブスク
    static func pendingSubscriptions(
        in subscriptions: [Subscription],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Subscription] {
        let month = targetMonth(now: now, calendar: calendar)
        return subscriptions.filter { subscription in
            isEligible(subscription, now: now, calendar: calendar)
                && subscription.checkIn(for: month) == nil
        }
    }

    /// ホームにチェックインを促すバナーを出すか
    static func needsCheckIn(
        _ subscriptions: [Subscription],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        !pendingSubscriptions(in: subscriptions, now: now, calendar: calendar).isEmpty
    }
}
