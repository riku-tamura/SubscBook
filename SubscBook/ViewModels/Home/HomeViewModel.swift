import Foundation
import Observation

/// ② ホームの状態と操作
@Observable
final class HomeViewModel {
    /// AI のひとことと解約候補の理由
    let insight = InsightViewModel()

    func summary(of subscriptions: [Subscription], now: Date = .now) -> HomeSummary {
        HomeSummary(subscriptions: subscriptions, now: now)
    }

    func insightFacts(of subscriptions: [Subscription], summary: HomeSummary, isPremium: Bool) -> MonthlyInsightFacts {
        insight.monthlyFacts(of: subscriptions, suggestions: summary.cancelSuggestions, isPremium: isPremium)
    }

    func cancelReasonFacts(of subscriptions: [Subscription], summary: HomeSummary, isPremium: Bool) -> [CancelReasonFacts] {
        insight.cancelReasonFacts(of: subscriptions, suggestions: summary.cancelSuggestions, isPremium: isPremium)
    }
}
