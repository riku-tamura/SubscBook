import Foundation

/// 未使用のサブスクを検出する（5.3）
///
/// 回答済みで最も新しい月と、その前月の両方が「使っていない」なら解約候補にする。
/// 未回答の月があると連続はそこで途切れる。
enum CancelSuggestionDetector {
    /// 解約候補とみなす連続未使用月数
    static let requiredUnusedMonths = 2

    /// 有効なサブスクから解約候補を抽出する。年間の支払額が大きい順。
    static func suggestions(for subscriptions: [Subscription]) -> [CancelSuggestion] {
        subscriptions
            .filter(\.isActive)
            .compactMap { subscription in
                let streak = unusedStreak(of: subscription.checkIns)
                guard streak >= requiredUnusedMonths else { return nil }
                return CancelSuggestion(
                    subscription: subscription,
                    unusedMonths: streak,
                    annualCost: subscription.annualCost
                )
            }
            .sorted { $0.annualCost > $1.annualCost }
    }

    /// 最新の回答月から遡って、連続して「使っていない」と回答された月数
    static func unusedStreak(of checkIns: [CheckIn]) -> Int {
        // 月ごとに最後の回答を採用する
        var latestByMonth: [YearMonth: CheckIn] = [:]
        for checkIn in checkIns {
            guard let month = checkIn.yearMonth else { continue }
            if let existing = latestByMonth[month], existing.answeredAt >= checkIn.answeredAt {
                continue
            }
            latestByMonth[month] = checkIn
        }

        guard var month = latestByMonth.keys.max() else { return 0 }
        var streak = 0
        while let checkIn = latestByMonth[month], !checkIn.used {
            streak += 1
            month = month.previous
        }
        return streak
    }
}
