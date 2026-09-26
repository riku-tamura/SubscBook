import Foundation
import Observation
import SwiftData

/// ⑤ 月次チェックイン。前月分が未回答のサブスクを1件ずつ聞く。
@Observable
final class CheckInViewModel {
    /// 聞くサブスクがないときの理由
    enum EmptyReason: Equatable {
        /// 契約中のサブスクがない
        case noSubscriptions
        /// 登録から1ヶ月たったサブスクがまだない（1ヶ月未満は聞かない）
        case notYetEligible
        /// 先月分はすべて回答済み
        case allAnswered
    }

    let month: YearMonth
    /// 開始時点で未回答だったサブスク（回答しても並びは変えない）
    let queue: [Subscription]
    /// 開始時点で聞くサブスクがなかった理由（聞くサブスクがある場合は nil）
    let emptyReason: EmptyReason?
    private(set) var index = 0

    init(subscriptions: [Subscription], now: Date = .now, calendar: Calendar = .current) {
        month = CheckInPolicy.targetMonth(now: now, calendar: calendar)
        queue = CheckInPolicy.pendingSubscriptions(in: subscriptions, now: now, calendar: calendar)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let active = subscriptions.filter(\.isActive)
        if !queue.isEmpty {
            emptyReason = nil
        } else if active.isEmpty {
            emptyReason = .noSubscriptions
        } else if !active.contains(where: { CheckInPolicy.isEligible($0, now: now, calendar: calendar) }) {
            emptyReason = .notYetEligible
        } else {
            emptyReason = .allAnswered
        }
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

    /// 回答を保存できなかったときのメッセージ（アラートで表示する）
    var saveErrorMessage: String?

    /// `subscription` への回答を記録して次へ進む。
    /// すでに別のサブスクに進んでいる場合（スワイプ中にボタンを押したなど）は何もしない。
    /// 保存できなかった場合は回答を取り消して進まない（回答済みと表示したのに、再起動すると消えていることがないように）。
    /// - Returns: 回答を記録して次へ進んだか
    @discardableResult
    func answer(used: Bool, for subscription: Subscription, in context: ModelContext, now: Date = .now) -> Bool {
        guard let current, current.id == subscription.id else { return false }
        current.recordCheckIn(for: month, used: used, at: now)
        do {
            try context.save()
        } catch {
            context.rollback()
            saveErrorMessage = "回答を保存できませんでした。もう一度お試しください。"
            return false
        }
        index += 1
        return true
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
