import Foundation

/// 同一カテゴリで重複しているサブスクのまとまり（5.4）
struct DuplicateGroup: Identifiable {
    let category: SubscriptionCategory
    /// 月額換算の大きい順
    let subscriptions: [Subscription]

    var id: SubscriptionCategory { category }

    var monthlyTotal: Int {
        subscriptions.reduce(0) { $0 + $1.monthlyEquivalent }
    }
}
