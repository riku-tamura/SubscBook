import Foundation

/// 一覧の並び順
nonisolated enum SubscriptionSortOrder: String, CaseIterable, Identifiable, Sendable {
    case paymentDate
    case price
    case category

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paymentDate: "支払日順"
        case .price: "金額順"
        case .category: "カテゴリ順"
        }
    }
}

/// 一覧画面に表示するセクション
struct SubscriptionListSections {
    let active: [Subscription]
    let canceled: [Subscription]

    init(subscriptions: [Subscription], sortOrder: SubscriptionSortOrder) {
        active = Self.sorted(subscriptions.filter(\.isActive), by: sortOrder)
        // 解約済みは解約日の新しい順
        canceled = subscriptions
            .filter { !$0.isActive }
            .sorted { ($0.canceledAt ?? .distantPast) > ($1.canceledAt ?? .distantPast) }
    }

    static func sorted(_ subscriptions: [Subscription], by order: SubscriptionSortOrder) -> [Subscription] {
        let categoryOrder = Dictionary(
            uniqueKeysWithValues: SubscriptionCategory.allCases.enumerated().map { ($1, $0) }
        )
        return subscriptions.sorted { lhs, rhs in
            switch order {
            case .paymentDate:
                if lhs.nextPaymentDate != rhs.nextPaymentDate {
                    return lhs.nextPaymentDate < rhs.nextPaymentDate
                }
            case .price:
                // 周期が違っても比べられるよう月額換算で比べる
                if lhs.monthlyEquivalent != rhs.monthlyEquivalent {
                    return lhs.monthlyEquivalent > rhs.monthlyEquivalent
                }
            case .category:
                if lhs.category != rhs.category {
                    return categoryOrder[lhs.category, default: 0] < categoryOrder[rhs.category, default: 0]
                }
                if lhs.nextPaymentDate != rhs.nextPaymentDate {
                    return lhs.nextPaymentDate < rhs.nextPaymentDate
                }
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
