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

    /// AI に渡す箇条書き（数値は含めない）。
    /// かぎ括弧を使うと、モデルが出力の文字列を 」 で閉じて読み取れなくなることがあるため使わない。
    var promptLines: [String] {
        [
            "サービス名：\(name)",
            "ジャンル：\(categoryName)",
            unusedMonths >= 3 ? "チェックインで、使っていないという回答が長く続いている" : "チェックインで、使っていないという回答が続いている",
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
