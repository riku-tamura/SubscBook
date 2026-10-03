import Foundation

/// 解約候補の理由（AI が言い換える元の文）を選ぶための事実
nonisolated struct CancelReasonFacts: Hashable, Sendable {
    let subscriptionID: UUID
    let name: String
    let categoryName: String
    let unusedMonths: Int
    let cycle: BillingCycle
    /// 同じカテゴリに他の有効なサブスクがあるか
    let hasSameCategoryAlternative: Bool
}
