import Foundation

/// 月次のひとことを決めるための事実（8.2）。何を伝えるかはアプリが決め（定型の文）、AI には言い換えだけを任せる。
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

    /// 事実にない話題の語。AI の文に含まれていたら使わない（例：解約候補がないのに「使っていない」と書く）。
    var contradictingTerms: [String] {
        var terms: [String] = []
        if !hasCancelCandidates {
            terms += ["使っていない", "利用していない"]
        }
        if !hasDuplicates {
            terms += ["重な", "重複"]
        }
        return terms
    }
}
