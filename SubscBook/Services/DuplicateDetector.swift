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

/// 重複の検出（5.4）
enum DuplicateDetector {
    /// 同一カテゴリで有効なサブスクが2件以上あるカテゴリを返す。「その他」は除外。カテゴリの定義順。
    static func duplicateGroups(in subscriptions: [Subscription]) -> [DuplicateGroup] {
        let grouped = Dictionary(grouping: subscriptions.filter(\.isActive), by: \.category)
        return SubscriptionCategory.allCases.compactMap { category in
            guard category.isDuplicateDetectionTarget,
                  let members = grouped[category], members.count >= 2
            else { return nil }
            return DuplicateGroup(
                category: category,
                subscriptions: members.sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
            )
        }
    }
}
