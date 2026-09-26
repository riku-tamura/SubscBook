import Foundation

/// 前月と比べた支払いの増減（ロジックで判定する）
nonisolated enum SpendingTrend: String, Hashable, Sendable {
    case increased
    case decreased
    case unchanged
    /// 前月のデータがない
    case unknown

    var promptText: String {
        switch self {
        case .increased: "増加"
        case .decreased: "減少"
        case .unchanged: "変化なし"
        case .unknown: "比較できるデータなし"
        }
    }
}
