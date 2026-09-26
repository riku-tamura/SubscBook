import Foundation

/// ホーム画面（②）に表示する集計値。数値はすべてロジックで計算する。
struct HomeSummary {
    let monthlyTotal: Int
    let annualTotal: Int
    let activeCount: Int
    /// 次の支払い予定（直近3件）
    let upcomingPayments: [Subscription]
    let cancelSuggestions: [CancelSuggestion]
    let needsCheckIn: Bool

    static let upcomingLimit = 3

    init(subscriptions: [Subscription], now: Date = .now, calendar: Calendar = .current) {
        let active = subscriptions.filter(\.isActive)
        monthlyTotal = CostCalculator.monthlyTotal(of: active)
        annualTotal = CostCalculator.annualTotal(of: active)
        activeCount = active.count
        upcomingPayments = Array(
            active.sorted { $0.nextPaymentDate < $1.nextPaymentDate }.prefix(Self.upcomingLimit)
        )
        cancelSuggestions = CancelSuggestionDetector.suggestions(for: active)
        needsCheckIn = MonthlyCheckInPolicy.needsCheckIn(active, now: now, calendar: calendar)
    }
}
