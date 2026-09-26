import Foundation

/// AI のコメント生成（8章）。AI 版とテンプレート版を同じ形で扱う。
nonisolated protocol InsightService: Sendable {
    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult
    func cancelReason(for facts: CancelReasonFacts) async -> InsightResult
}
