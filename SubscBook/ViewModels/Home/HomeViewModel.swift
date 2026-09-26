import Foundation
import Observation

/// ② ホームの状態と操作
@Observable
final class HomeViewModel {
    /// AI の月次のひとこと
    private(set) var comment: String?
    /// 解約候補の理由（サブスク帳プラスのみ）
    private(set) var cancelReasons: [UUID: String] = [:]

    func summary(of subscriptions: [Subscription], now: Date = .now) -> HomeSummary {
        HomeSummary(subscriptions: subscriptions, now: now)
    }

    /// AI に渡す月次の事実
    func insightFacts(of subscriptions: [Subscription], summary: HomeSummary, isPremium: Bool) -> MonthlyInsightFacts {
        InsightFactsBuilder.monthly(
            subscriptions: subscriptions,
            isPremium: isPremium,
            suggestions: summary.cancelSuggestions
        )
    }

    /// 解約候補の理由はサブスク帳プラスのみ AI で作る（無料はぼかし表示なので作らない）
    func cancelReasonFacts(of subscriptions: [Subscription], summary: HomeSummary, isPremium: Bool) -> [CancelReasonFacts] {
        guard isPremium else { return [] }
        return summary.cancelSuggestions.map { InsightFactsBuilder.cancelReason(for: $0, among: subscriptions) }
    }

    func loadComment(for facts: MonthlyInsightFacts, using insights: InsightProvider) async {
        let text = await insights.monthlyComment(for: facts)
        // 生成中に事実が変わった場合は、古い結果で上書きしない
        guard !Task.isCancelled else { return }
        comment = text
    }

    func loadCancelReasons(for facts: [CancelReasonFacts], using insights: InsightProvider) async {
        let reasons = await insights.cancelReasons(for: facts)
        guard !Task.isCancelled else { return }
        cancelReasons = reasons
    }
}
