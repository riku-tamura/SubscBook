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

/// AI の月次振り返りに渡す事実（8.2）。数値の計算・判定は済ませてあり、AI には文章化だけを任せる。
nonisolated struct MonthlyInsightFacts: Hashable, Sendable {
    let activeCount: Int
    let trend: SpendingTrend
    /// 解約候補（サブスク帳プラスのみサービス名を渡す）
    let cancelCandidates: [CandidateFact]
    /// 名前を伏せた解約候補の件数（無料プラン）
    let hiddenCancelCandidateCount: Int
    /// 重複カテゴリ（サブスク帳プラスのみカテゴリ名を渡す）
    let duplicateCategories: [DuplicateFact]
    /// 名前を伏せた重複カテゴリの件数（無料プラン）
    let hiddenDuplicateCount: Int
    let canceledThisMonthCount: Int

    struct CandidateFact: Hashable, Sendable {
        let name: String
        let unusedMonths: Int
    }

    struct DuplicateFact: Hashable, Sendable {
        let categoryName: String
        let count: Int
    }

    var hasCancelCandidates: Bool {
        !cancelCandidates.isEmpty || hiddenCancelCandidateCount > 0
    }

    var hasDuplicates: Bool {
        !duplicateCategories.isEmpty || hiddenDuplicateCount > 0
    }

    /// AI に渡す箇条書き。AI が数値をまねて書かないよう、件数などの数値は含めない。
    var promptLines: [String] {
        var lines: [String] = []
        switch trend {
        case .increased: lines.append("支払いの合計は先月より増えた")
        case .decreased: lines.append("支払いの合計は先月より減った")
        case .unchanged: lines.append("支払いの合計は先月と変わらない")
        case .unknown: lines.append("先月と比べられるデータはまだない")
        }
        if !cancelCandidates.isEmpty {
            lines += cancelCandidates.map { "\($0.name) をしばらく使っていない" }
        } else if hiddenCancelCandidateCount > 0 {
            lines.append("しばらく使っていないサブスクがある")
        } else {
            lines.append("使っていないサブスクはない")
        }
        if !duplicateCategories.isEmpty {
            lines += duplicateCategories.map { "\($0.categoryName)のサブスクが重なっている" }
        } else if hiddenDuplicateCount > 0 {
            lines.append("同じジャンルで重なっているサブスクがある")
        } else {
            lines.append("重なっているジャンルはない")
        }
        if canceledThisMonthCount > 0 {
            lines.append("今月サブスクを解約した")
        }
        return lines.map { "- \($0)" }
    }

    /// 出力に含まれてもよい固有名詞（数字を含むサービス名など）
    var allowedTerms: [String] {
        cancelCandidates.map(\.name) + duplicateCategories.map(\.categoryName)
    }

    /// キャッシュの判定に使う。事実が変わったときだけ作り直す。
    var cacheKey: String {
        promptLines.joined(separator: "\n")
    }
}

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
