import Foundation

/// テンプレート文（8.6）。AI が使えない端末や、生成に失敗したときに使う。
/// 月次のひとことは、AI が言い換える元の文にもなる（何を伝えるかはここで決める）。
nonisolated struct TemplateInsightService: InsightService {
    static let monthlyDefault = "今月もサブスク帳にまとめています。気になるサブスクがないか見直してみましょう。"
    static let cancelReasonDefault = "「使っていない」月が続いています。続けるか見直してみませんか？"

    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult {
        InsightResult(text: Self.monthlyText(for: facts), isGenerated: false)
    }

    func cancelReason(for facts: CancelReasonFacts) async -> InsightResult {
        InsightResult(text: Self.cancelReasonText(for: facts), isGenerated: false)
    }

    static func monthlyText(for facts: MonthlyInsightFacts) -> String {
        if facts.hasCancelCandidates {
            return "チェックインで「使っていない」という回答が続いているサブスクがあります。続けるか見直してみませんか？"
        }
        if facts.hasDuplicates {
            return "同じジャンルのサブスクが重なっています。まとめられないか考えてみましょう。"
        }
        if facts.canceledThisMonthCount > 0 {
            return "今月は見直しが進みました。この調子で続けていきましょう。"
        }
        switch facts.trend {
        case .increased:
            return "先月より支払いが増えています。新しいサブスクが本当に必要か確かめてみましょう。"
        case .decreased:
            return "先月より支払いが減りました。この調子で見直しを続けましょう。"
        case .unchanged, .unknown:
            return monthlyDefault
        }
    }

    static func cancelReasonText(for facts: CancelReasonFacts) -> String {
        if facts.hasSameCategoryAlternative {
            return "「使っていない」月が続いていて、同じジャンルのサービスも契約中です。まとめられないか見直してみませんか？"
        }
        if facts.cycle == .yearly {
            return "「使っていない」月が続いています。次の更新の前に、続けるか考えてみませんか？"
        }
        return cancelReasonDefault
    }
}
