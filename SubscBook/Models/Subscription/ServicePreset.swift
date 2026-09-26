import Foundation

/// サービス名入力時の候補。ロゴは使わず、名前とカテゴリだけを持つ。
nonisolated struct ServicePreset: Hashable, Identifiable, Sendable {
    let name: String
    let category: SubscriptionCategory
    /// 検索用の読み（カタカナ）
    let reading: String

    var id: String { name }
}
