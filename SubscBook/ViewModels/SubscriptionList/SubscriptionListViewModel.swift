import Foundation
import Observation

/// ③ サブスク一覧の状態と操作
@Observable
final class SubscriptionListViewModel {
    static let sortOrderKey = "list.sortOrder"

    /// 並び順（次回の起動でも同じ順で表示する）
    var sortOrder: SubscriptionSortOrder {
        didSet { defaults.set(sortOrder.rawValue, forKey: Self.sortOrderKey) }
    }
    /// 解約済みのセクションを開いているか
    var isCanceledExpanded = false

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sortOrder = defaults.string(forKey: Self.sortOrderKey).flatMap(SubscriptionSortOrder.init(rawValue:)) ?? .paymentDate
    }

    func sections(of subscriptions: [Subscription]) -> SubscriptionListSections {
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
