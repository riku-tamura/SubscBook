import Foundation

/// ペイウォールを表示したきっかけ（7章）
nonisolated enum PaywallReason: Hashable, Identifiable, Sendable {
    /// 6件目のサブスクを登録しようとした
    case subscriptionLimit
    /// ロックされた有料機能をタップした
    case lockedFeature(PremiumFeature)
    /// 設定画面から開いた
    case settings

    var id: Self { self }
}

/// ペイウォールを開いたきっかけに合わせた見出し
extension PaywallReason {
    var headline: String {
        switch self {
        case .subscriptionLimit: "サブスクを無制限に登録"
        case .lockedFeature(let feature): feature.title
        case .settings: "節約をもっと確実に"
        }
    }

    var message: String {
        switch self {
        case .subscriptionLimit:
            "無料プランで登録できるのは\(FreePlan.subscriptionLimit)件までです。サブスク帳プラスなら、すべてのサブスクをまとめて管理できます。"
        case .lockedFeature:
            "この機能はサブスク帳プラスでご利用いただけます。"
        case .settings:
            "毎月のチェックインをもとに、使っていないサブスクや重複を見つけて、見直しを後押しします。"
        }
    }
}
