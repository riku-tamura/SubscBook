import Foundation

/// ⑥ 振り返りレポートに表示する集計値。数値はすべてロジックで計算する。
struct ReportSummary {
    /// 振り返りの対象月（今月）
    let month: YearMonth
    let monthlyTotal: Int
    let annualTotal: Int
    let activeCount: Int
    let breakdown: CategoryBreakdown
    let cancelSuggestions: [CancelSuggestion]
    let duplicateGroups: [DuplicateGroup]
    let savings: SavingsSummary

    init(subscriptions: [Subscription], now: Date = .now, calendar: Calendar = .current) {
        let active = subscriptions.filter(\.isActive)
        month = YearMonth(date: now, calendar: calendar)
        monthlyTotal = CostCalculator.monthlyTotal(of: active)
        annualTotal = CostCalculator.annualTotal(of: active)
        activeCount = active.count
        breakdown = CategoryBreakdown(subscriptions: active)
        cancelSuggestions = CancelSuggestionDetector.suggestions(for: active)
        duplicateGroups = DuplicateDetector.duplicateGroups(in: active)
        savings = SavingsSummary(subscriptions: subscriptions, now: now, calendar: calendar)
    }
}
