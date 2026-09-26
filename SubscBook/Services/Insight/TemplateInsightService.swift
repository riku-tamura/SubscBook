import Foundation

/// テンプレート文（8.6）。AI が使えない端末や、生成に失敗したときに使う。
nonisolated struct TemplateInsightService: InsightService {
    static let monthlyDefault = "今月も見張りを続けています。気になるサブスクがないかチェックしてみましょう。"
    static let cancelReasonDefault = "しばらく使っていないようです。続けるか見直してみませんか？"

    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult {
        InsightResult(text: Self.monthlyText(for: facts), isGenerated: false)
    }

    func cancelReason(for facts: CancelReasonFacts) async -> InsightResult {
        InsightResult(text: Self.cancelReasonText(for: facts), isGenerated: false)
    }

    static func monthlyText(for facts: MonthlyInsightFacts) -> String {
        if facts.hasCancelCandidates {
            return "しばらく使っていないサブスクがあるようです。続けるか見直してみませんか？"
        }
        if facts.hasDuplicates {
            return "同じジャンルのサブスクが重なっています。まとめられないか考えてみましょう。"
        }
        if facts.canceledThisMonthCount > 0 {
            return "今月は見直しが進みました。この調子で見張りを続けましょう。"
        }
        switch facts.trend {
        case .increased:
            return "先月より支払いが増えています。新しいサブスクが本当に必要か確かめてみましょう。"
        case .decreased:
            return "先月より支払いが減りました。この調子で見張りを続けましょう。"
        case .unchanged, .unknown:
            return monthlyDefault
        }
    }

    static func cancelReasonText(for facts: CancelReasonFacts) -> String {
        if facts.hasSameCategoryAlternative {
            return "しばらく使っておらず、同じジャンルのサービスも契約中です。まとめられないか見直してみませんか？"
        }
        if facts.cycle == .yearly {
            return "しばらく使っていないようです。次の更新の前に、続けるか考えてみませんか？"
        }
        return cancelReasonDefault
    }
}
