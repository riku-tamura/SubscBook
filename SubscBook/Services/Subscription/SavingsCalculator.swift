import Foundation

/// 節約額（5.5）
enum SavingsCalculator {
    /// 年間節約額：解約済みサブスクの1年あたりの支払額の合計
    static func annualSavings(of subscriptions: [Subscription]) -> Int {
        canceled(in: subscriptions).reduce(0) { $0 + $1.annualCost }
    }

    /// 実際の節約累計：解約日から今日までの満了月数 × 月額換算 の合計
    static func realizedSavings(
        of subscriptions: [Subscription],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        canceled(in: subscriptions).reduce(0) { total, subscription in
            guard let canceledAt = subscription.canceledAt else { return total }
            let months = elapsedFullMonths(from: canceledAt, to: now, calendar: calendar)
            return total + months * subscription.monthlyEquivalent
        }
    }

    /// `from` から `to` までの満了月数（切り捨て）。日単位で比較し、時刻は無視する。
    nonisolated static func elapsedFullMonths(from: Date, to: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: to)
        guard start < end else { return 0 }
        return max(0, calendar.dateComponents([.month], from: start, to: end).month ?? 0)
    }

    private static func canceled(in subscriptions: [Subscription]) -> [Subscription] {
        subscriptions.filter { $0.status == .canceled }
    }
}
