import Foundation
import Observation

/// AI のひとことと解約候補の理由の読み込み（ホーム・レポート共通）
@Observable
final class InsightViewModel {
    /// AI の月次のひとこと
    private(set) var comment: String?
    /// ひとことを Apple Intelligence で作れたか（false は定型のコメント）
    private(set) var isCommentGenerated = false
    /// 解約候補の理由（サブスク帳プラスのみ）
    private(set) var cancelReasons: [UUID: String] = [:]

    /// AI に渡す月次の事実（計算済みの解約候補・重複を使う）
    func monthlyFacts(
        of subscriptions: [Subscription],
        suggestions: [CancelSuggestion],
        duplicates: [DuplicateGroup]? = nil,
        isPremium: Bool
    ) -> MonthlyInsightFacts {
        InsightFactsBuilder.monthly(
            subscriptions: subscriptions,
            isPremium: isPremium,
            suggestions: suggestions,
            duplicates: duplicates
        )
    }

    /// 解約候補の理由はサブスク帳プラスのみ AI で作る（無料はぼかし表示なので作らない）
    func cancelReasonFacts(of subscriptions: [Subscription], suggestions: [CancelSuggestion], isPremium: Bool) -> [CancelReasonFacts] {
        guard isPremium else { return [] }
        return suggestions.map { InsightFactsBuilder.cancelReason(for: $0, among: subscriptions) }
    }

    func loadComment(for facts: MonthlyInsightFacts, using insights: InsightProvider) async {
        let result = await insights.monthlyComment(for: facts)
        // 生成中に事実が変わった場合は、古い結果で上書きしない
        guard !Task.isCancelled else { return }
        comment = result.text
        isCommentGenerated = result.isGenerated
    }

    /// 理由は1件できるたびに表示する。候補から外れたサブスクの理由は消す。
    func loadCancelReasons(for facts: [CancelReasonFacts], using insights: InsightProvider) async {
        let ids = Set(facts.map(\.subscriptionID))
        cancelReasons = cancelReasons.filter { ids.contains($0.key) }
        for item in facts {
            let text = await insights.cancelReason(for: item)
            guard !Task.isCancelled else { return }
            cancelReasons[item.subscriptionID] = text
        }
    }
}
