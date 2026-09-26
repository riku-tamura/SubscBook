import Foundation

/// 無料プランの制限（6章）
nonisolated enum FreePlan {
    /// 無料プランで登録できる有効なサブスクの上限
    static let subscriptionLimit = 5

    static func canAddSubscription(activeCount: Int, isPremium: Bool) -> Bool {
        isPremium || activeCount < subscriptionLimit
    }
}
