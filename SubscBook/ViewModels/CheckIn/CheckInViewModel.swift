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
        month = CheckInPolicy.targetMonth(now: now, calendar: calendar)
        queue = CheckInPolicy.pendingSubscriptions(in: subscriptions, now: now, calendar: calendar)
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

    /// `subscription` への回答を記録して次へ進む。
    /// すでに別のサブスクに進んでいる場合（スワイプ中にボタンを押したなど）は何もしない。
    func answer(used: Bool, for subscription: Subscription, in context: ModelContext, now: Date = .now) {
        guard let current, current.id == subscription.id else { return }
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
