import Foundation
import Observation

/// ③ サブスク一覧の状態と操作
@Observable
final class SubscriptionListViewModel {
    /// 解約済みのセクションを開いているか
    var isCanceledExpanded = false

    func sections(of subscriptions: [Subscription], sortOrder: SubscriptionSortOrder) -> SubscriptionListSections {
        SubscriptionListSections(subscriptions: subscriptions, sortOrder: sortOrder)
    }

    func toggleCanceledSection() {
        isCanceledExpanded.toggle()
    }

    /// 無料プランの残り件数の案内
    func freePlanMessage(activeCount: Int) -> String {
        let remaining = max(0, FreePlan.subscriptionLimit - activeCount)
        return remaining > 0
            ? "無料プランでは\(FreePlan.subscriptionLimit)件まで登録できます（あと\(remaining)件）。"
            : "無料プランの上限（\(FreePlan.subscriptionLimit)件）に達しました。サブスク帳プラスなら無制限に登録できます。"
    }
}
