import Foundation

/// 前月と比べた支払いの増減（ロジックで判定する）
nonisolated enum SpendingTrend: String, Hashable, Sendable {
    case increased
    case decreased
    case unchanged
    /// 前月のデータがない
    case unknown
}
