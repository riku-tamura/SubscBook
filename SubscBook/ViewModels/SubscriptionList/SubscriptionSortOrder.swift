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
