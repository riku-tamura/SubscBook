import Foundation

/// サブスクのデータから、AI に渡す事実を組み立てる（8.2）
enum InsightFactsBuilder {
    /// 月次振り返りの事実。無料プランでは解約候補・重複の詳細（有料機能）を伏せて件数だけ渡す。
    static func monthly(
        subscriptions: [Subscription],
        isPremium: Bool,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> MonthlyInsightFacts {
        let active = subscriptions.filter(\.isActive)
        let suggestions = CancelSuggestionDetector.suggestions(for: active)
        let duplicates = DuplicateDetector.duplicateGroups(in: active)
        let startOfMonth = YearMonth(date: now, calendar: calendar).startDate(calendar: calendar)
        let canceledThisMonth = subscriptions.filter {
            !$0.isActive && ($0.canceledAt.map { $0 >= startOfMonth } ?? false)
        }

        return MonthlyInsightFacts(
            activeCount: active.count,
            trend: trend(of: subscriptions, now: now, calendar: calendar),
            cancelCandidates: isPremium
                ? suggestions.map { .init(name: $0.subscription.name, unusedMonths: $0.unusedMonths) }
                : [],
            hiddenCancelCandidateCount: isPremium ? 0 : suggestions.count,
            duplicateCategories: isPremium
                ? duplicates.map { .init(categoryName: $0.category.displayName, count: $0.subscriptions.count) }
                : [],
            hiddenDuplicateCount: isPremium ? 0 : duplicates.count,
            canceledThisMonthCount: canceledThisMonth.count
        )
    }

    /// 前月末と今の月額合計を比べる。前月末に契約中だったサブスクがなければ比較しない。
    static func trend(
        of subscriptions: [Subscription],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> SpendingTrend {
        let startOfMonth = YearMonth(date: now, calendar: calendar).startDate(calendar: calendar)
        let activeAtPreviousMonthEnd = subscriptions.filter { subscription in
            guard subscription.createdAt < startOfMonth else { return false }
            if subscription.isActive { return true }
            return (subscription.canceledAt ?? .distantPast) >= startOfMonth
        }
        guard !activeAtPreviousMonthEnd.isEmpty else { return .unknown }

        let previousTotal = activeAtPreviousMonthEnd.reduce(0) { $0 + $1.monthlyEquivalent }
        let currentTotal = CostCalculator.monthlyTotal(of: subscriptions)
        if currentTotal > previousTotal { return .increased }
        if currentTotal < previousTotal { return .decreased }
        return .unchanged
    }

    static func cancelReason(for suggestion: CancelSuggestion, among subscriptions: [Subscription]) -> CancelReasonFacts {
        let subscription = suggestion.subscription
        let hasAlternative = subscriptions.contains {
            $0.isActive && $0.id != subscription.id && $0.category == subscription.category
                && subscription.category.isDuplicateDetectionTarget
        }
        return CancelReasonFacts(
            subscriptionID: subscription.id,
            name: subscription.name,
            categoryName: subscription.category.displayName,
            unusedMonths: suggestion.unusedMonths,
            cycle: subscription.cycle,
            hasSameCategoryAlternative: hasAlternative
        )
    }
}
