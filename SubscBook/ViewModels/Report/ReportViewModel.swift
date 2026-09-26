import Foundation
import Observation
import SwiftUI

/// ⑥ 振り返りレポートの状態と操作
@Observable
final class ReportViewModel {
    /// AI の月次振り返りと解約候補の理由
    let insight = InsightViewModel()
    /// SNS 共有用の画像（サブスク帳プラスで、解約したサブスクがある場合のみ）
    private(set) var shareImage: Image?

    func summary(of subscriptions: [Subscription], now: Date = .now) -> ReportSummary {
        ReportSummary(subscriptions: subscriptions, now: now)
    }

    func insightFacts(of subscriptions: [Subscription], summary: ReportSummary, isPremium: Bool) -> MonthlyInsightFacts {
        insight.monthlyFacts(
            of: subscriptions,
            suggestions: summary.cancelSuggestions,
            duplicates: summary.duplicateGroups,
            isPremium: isPremium
        )
    }

    func cancelReasonFacts(of subscriptions: [Subscription], summary: ReportSummary, isPremium: Bool) -> [CancelReasonFacts] {
        insight.cancelReasonFacts(of: subscriptions, suggestions: summary.cancelSuggestions, isPremium: isPremium)
    }

    /// 共有用の画像を作り直す。無料プランや解約がない場合は作らない。
    func updateShareImage(for savings: SavingsSummary, isPremium: Bool) {
        guard isPremium, savings.hasSavings else {
            shareImage = nil
            return
        }
        shareImage = ReportShareImage.render(savings: savings)
    }
}
