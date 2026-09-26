import Foundation

/// カテゴリ別の月額（⑥ レポートの円グラフ）
struct CategorySlice: Identifiable, Hashable {
    let category: SubscriptionCategory
    let monthlyTotal: Int
    let count: Int
    /// 全体に占める割合（0.0〜1.0）
    let share: Double

    var id: SubscriptionCategory { category }
}

enum CategoryBreakdown {
    /// 有効なサブスクをカテゴリ別に集計する。色の並びを保つため、カテゴリの定義順で返す。
    static func slices(of subscriptions: [Subscription]) -> [CategorySlice] {
        let active = subscriptions.filter(\.isActive)
        let total = CostCalculator.monthlyTotal(of: active)
        guard total > 0 else { return [] }
        let grouped = Dictionary(grouping: active, by: \.category)
        return SubscriptionCategory.allCases.compactMap { category in
            guard let members = grouped[category] else { return nil }
            let monthlyTotal = CostCalculator.monthlyTotal(of: members)
            guard monthlyTotal > 0 else { return nil }
            return CategorySlice(
                category: category,
                monthlyTotal: monthlyTotal,
                count: members.count,
                share: Double(monthlyTotal) / Double(total)
            )
        }
    }
}
