import Foundation

/// 節約の実績（5.5）
struct SavingsSummary: Equatable {
    /// 解約済みサブスクの1年あたりの支払額の合計
    let annualSavings: Int
    /// 解約日から今日までの満了月数 × 月額換算の合計
    let realizedSavings: Int
    let canceledCount: Int

    init(subscriptions: [Subscription], now: Date = .now, calendar: Calendar = .current) {
        annualSavings = SavingsCalculator.annualSavings(of: subscriptions)
        realizedSavings = SavingsCalculator.realizedSavings(of: subscriptions, now: now, calendar: calendar)
        canceledCount = subscriptions.filter { !$0.isActive }.count
    }

    init(annualSavings: Int, realizedSavings: Int, canceledCount: Int) {
        self.annualSavings = annualSavings
        self.realizedSavings = realizedSavings
        self.canceledCount = canceledCount
    }

    var hasSavings: Bool { canceledCount > 0 }
}
