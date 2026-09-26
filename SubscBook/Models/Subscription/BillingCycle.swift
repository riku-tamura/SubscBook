import Foundation

/// 支払い周期
nonisolated enum BillingCycle: String, Codable, CaseIterable, Identifiable, Sendable {
    case monthly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly: "毎月"
        case .yearly: "毎年"
        }
    }

    /// 金額の後ろに付ける単位（例：「1,200円/月」）
    var unitLabel: String {
        switch self {
        case .monthly: "月"
        case .yearly: "年"
        }
    }

    /// 1周期あたりの月数
    var months: Int {
        switch self {
        case .monthly: 1
        case .yearly: 12
        }
    }
}
