import Foundation
import Observation
import SwiftData

/// ⑤ 月次チェックイン。前月分が未回答のサブスクを1件ずつ聞く。
@Observable
final class CheckInViewModel {
    let month: YearMonth
    /// 開始時点で未回答だったサブスク（回答しても並びは変えない）
    let queue: [Subscription]
    private(set) var index = 0

    init(subscriptions: [Subscription], now: Date = .now, calendar: Calendar = .current) {
        month = MonthlyCheckInPolicy.targetMonth(now: now, calendar: calendar)
        queue = MonthlyCheckInPolicy.pendingSubscriptions(in: subscriptions, now: now, calendar: calendar)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var current: Subscription? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    var isFinished: Bool { current == nil }

    var canGoBack: Bool { index > 0 }

    /// 0.0〜1.0
    var progress: Double {
        queue.isEmpty ? 1 : Double(index) / Double(queue.count)
    }

    var progressText: String {
        "\(min(index + 1, queue.count)) / \(queue.count)"
    }

    func answer(used: Bool, in context: ModelContext, now: Date = .now) {
        guard let current else { return }
        current.recordCheckIn(for: month, used: used, at: now)
        try? context.save()
        index += 1
    }

    /// ひとつ前のサブスクに戻る（回答は上書きできる）
    func goBack() {
        guard canGoBack else { return }
        index -= 1
    }

    /// 全件回答後に、解約候補になったサブスク
    func cancelSuggestions(among subscriptions: [Subscription]) -> [CancelSuggestion] {
        CancelSuggestionDetector.suggestions(for: subscriptions)
    }
}
