import Foundation

/// 金額計算（5.1）
enum CostCalculator {
    /// 月額換算。年額は 12 で割って四捨五入する。負の金額は 0 として扱う。
    nonisolated static func monthlyEquivalent(price: Int, cycle: BillingCycle) -> Int {
        let price = max(0, price)
        switch cycle {
        case .monthly:
            return price
        case .yearly:
            // 整数演算で四捨五入（端数 0.5 は切り上げ）
            return (price + 6) / 12
        }
    }

    /// 1年あたりの支払額。月額は × 12、年額はそのまま。
    nonisolated static func annualCost(price: Int, cycle: BillingCycle) -> Int {
        let price = max(0, price)
        switch cycle {
        case .monthly: return price * 12
        case .yearly: return price
        }
    }

    /// 有効なサブスクの月額換算の合計
    static func monthlyTotal(of subscriptions: [Subscription]) -> Int {
        subscriptions
            .filter(\.isActive)
            .reduce(0) { $0 + $1.monthlyEquivalent }
    }

    /// 年額合計。年額プランは実際の金額で合計する（年額10,000円が 9,996円 と表示されないように）
    static func annualTotal(of subscriptions: [Subscription]) -> Int {
        subscriptions
            .filter(\.isActive)
            .reduce(0) { $0 + $1.annualCost }
    }
}
