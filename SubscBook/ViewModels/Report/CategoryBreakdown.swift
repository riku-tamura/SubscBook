import Foundation

/// カテゴリ別の月額（⑥ レポートの円グラフ）
struct CategoryBreakdown: Equatable {
    /// 円グラフの1区分
    struct Slice: Identifiable, Hashable {
        let category: SubscriptionCategory
        let monthlyTotal: Int
        let count: Int
        /// 全体に占める割合（0.0〜1.0）
        let share: Double

        var id: SubscriptionCategory { category }
    }

    /// 色の並びを保つため、カテゴリの定義順
    let slices: [Slice]
    /// 有効なサブスクの月額換算の合計
    let monthlyTotal: Int

    var isEmpty: Bool { slices.isEmpty }

    /// 有効なサブスクをカテゴリ別に集計する
    init(subscriptions: [Subscription]) {
        let active = subscriptions.filter(\.isActive)
        let total = CostCalculator.monthlyTotal(of: active)
        monthlyTotal = total
        guard total > 0 else {
            slices = []
            return
        }
        let grouped = Dictionary(grouping: active, by: \.category)
        slices = SubscriptionCategory.allCases.compactMap { category in
            guard let members = grouped[category] else { return nil }
            let categoryTotal = CostCalculator.monthlyTotal(of: members)
            guard categoryTotal > 0 else { return nil }
            return Slice(
                category: category,
                monthlyTotal: categoryTotal,
                count: members.count,
                share: Double(categoryTotal) / Double(total)
            )
        }
    }
}
