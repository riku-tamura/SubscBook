import Foundation

/// 登録するローカル通知1件分
nonisolated struct PlannedNotification: Equatable, Sendable {
    enum Kind: String, Sendable {
        /// 支払日の前日
        case payment
        /// 無料トライアル終了の3日前・前日
        case trial
        /// 毎月1日の月次チェックイン
        case checkIn
    }

    enum Trigger: Equatable, Sendable {
        /// 指定日時に1回
        case once(Date)
        /// 毎月、指定日・時刻に繰り返す
        case monthly(day: Int, hour: Int)
    }

    let identifier: String
    let kind: Kind
    let title: String
    let body: String
    let trigger: Trigger
    var subscriptionID: UUID?
}

/// 通知の予定を組み立てる（9章）。登録は `NotificationScheduler` が行う。
enum NotificationPlanner {
    /// iOS のローカル通知の上限
    static let maxPendingRequests = 64
    static let reminderHour = 9
    static let checkInDay = 1
    static let checkInHour = 20
    /// 月額サブスクは先の支払いまで登録しておく（アプリを開かない月があっても通知が届くように）
    static let upcomingMonthlyPayments = 3
    static let trialReminderDaysBefore = [3, 1]

    static func plan(
        subscriptions: [Subscription],
        isPremium: Bool,
        preferences: NotificationPreferences,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [PlannedNotification] {
        let active = subscriptions.filter(\.isActive)
        var oneShots: [(date: Date, notification: PlannedNotification)] = []

        if preferences.paymentReminder {
            for subscription in active {
                oneShots += paymentReminders(for: subscription, now: now, calendar: calendar)
            }
        }
        // トライアル終了の通知はサブスク帳プラスの機能
        if preferences.trialReminder && isPremium {
            for subscription in active {
                oneShots += trialReminders(for: subscription, now: now, calendar: calendar)
            }
        }

        var repeating: [PlannedNotification] = []
        if preferences.checkInReminder && !active.isEmpty {
            repeating.append(PlannedNotification(
                identifier: "checkIn.monthly",
                kind: .checkIn,
                title: "月次チェックインの時間です",
                body: "先月使ったサブスクを振り返って、見張りを続けましょう。",
                trigger: .monthly(day: checkInDay, hour: checkInHour)
            ))
        }

        // 上限を超える場合は直近の予定を優先する
        let limit = maxPendingRequests - repeating.count
        let nearest = oneShots
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map(\.notification)
        return repeating + nearest
    }

    private static func paymentReminders(
        for subscription: Subscription,
        now: Date,
        calendar: Calendar
    ) -> [(date: Date, notification: PlannedNotification)] {
        let occurrences = subscription.cycle == .monthly ? upcomingMonthlyPayments : 1
        var paymentDate = PaymentDateCalculator.advancedPaymentDate(
            from: subscription.nextPaymentDate,
            cycle: subscription.cycle,
            billingDay: subscription.billingDay,
            now: now,
            calendar: calendar
        )
        var result: [(Date, PlannedNotification)] = []
        for _ in 0..<occurrences {
            if let fireDate = reminderDate(daysBefore: 1, date: paymentDate, calendar: calendar), fireDate > now {
                result.append((fireDate, PlannedNotification(
                    identifier: "payment.\(subscription.id.uuidString).\(Int(paymentDate.timeIntervalSince1970))",
                    kind: .payment,
                    title: "明日は「\(subscription.name)」の支払日です",
                    body: "\(subscription.price.yenText)（\(subscription.cycle.displayName)）の支払いが予定されています。",
                    trigger: .once(fireDate),
                    subscriptionID: subscription.id
                )))
            }
            paymentDate = PaymentDateCalculator.paymentDate(
                after: paymentDate, cycle: subscription.cycle, billingDay: subscription.billingDay, calendar: calendar
            )
        }
        return result
    }

    private static func trialReminders(
        for subscription: Subscription,
        now: Date,
        calendar: Calendar
    ) -> [(date: Date, notification: PlannedNotification)] {
        guard let trialEndDate = subscription.trialEndDate else { return [] }
        return trialReminderDaysBefore.compactMap { days in
            guard let fireDate = reminderDate(daysBefore: days, date: trialEndDate, calendar: calendar),
                  fireDate > now
            else { return nil }
            let when = days == 1 ? "明日で" : "あと\(days)日で"
            return (fireDate, PlannedNotification(
                identifier: "trial.\(subscription.id.uuidString).\(days)",
                kind: .trial,
                title: "「\(subscription.name)」の無料トライアルが\(when)終わります",
                body: "続けない場合は、終了日までに解約手続きをしておきましょう。",
                trigger: .once(fireDate),
                subscriptionID: subscription.id
            ))
        }
    }

    /// `date` の `days` 日前の 9:00
    private static func reminderDate(daysBefore days: Int, date: Date, calendar: Calendar) -> Date? {
        guard let day = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: date)) else {
            return nil
        }
        return calendar.date(bySettingHour: reminderHour, minute: 0, second: 0, of: day)
    }
}
