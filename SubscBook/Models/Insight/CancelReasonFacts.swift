import Foundation

/// 解約候補の理由説明に渡す事実
nonisolated struct CancelReasonFacts: Hashable, Sendable {
    let subscriptionID: UUID
    let name: String
    let categoryName: String
    let unusedMonths: Int
    let cycle: BillingCycle
    /// 同じカテゴリに他の有効なサブスクがあるか
    let hasSameCategoryAlternative: Bool

    /// AI に渡す箇条書き（数値は含めない）
    var promptLines: [String] {
        [
            "サービス名：\(name)",
            "ジャンル：\(categoryName)",
            unusedMonths >= 3 ? "長いあいだ使っていない" : "最近使っていない",
            cycle == .monthly ? "支払いは毎月" : "支払いは毎年",
            hasSameCategoryAlternative ? "同じジャンルの別のサブスクも契約している" : "同じジャンルの別のサブスクは契約していない",
        ].map { "- \($0)" }
    }

    var allowedTerms: [String] {
        [name, categoryName]
    }

    var cacheKey: String {
        "\(subscriptionID.uuidString)|\(unusedMonths)|\(promptLines.joined(separator: "|"))"
    }
}
