import Foundation
import Testing
@testable import SubWatch

@Suite("解約候補の判定（5.3）")
struct CancelSuggestionDetectorTests {
    /// 月ごとの回答を古い順に記録する
    private func record(_ answers: [(String, Bool)], to subscription: Subscription) {
        for (index, (month, used)) in answers.enumerated() {
            subscription.recordCheckIn(for: YearMonth(month)!, used: used, at: date(2026, 1, 1).addingTimeInterval(Double(index)))
        }
    }

    @Test("最新の回答月と前月が「使っていない」なら解約候補")
    func twoConsecutiveUnused() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(price: 1490)
        record([("2026-07", false), ("2026-08", false)], to: subscription)

        let suggestions = CancelSuggestionDetector.suggestions(for: [subscription])

        #expect(suggestions.count == 1)
        #expect(suggestions.first?.subscription.id == subscription.id)
        #expect(suggestions.first?.unusedMonths == 2)
        #expect(suggestions.first?.annualCost == 1490 * 12)
    }

    @Test("連続未使用月数を数える")
    func countsStreak() throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        record([("2026-05", true), ("2026-06", false), ("2026-07", false), ("2026-08", false)], to: subscription)

        #expect(CancelSuggestionDetector.suggestions(for: [subscription]).first?.unusedMonths == 3)
    }

    @Test("候補にならないケース", arguments: [
        [("2026-08", false)],                                       // 1ヶ月だけ
        [("2026-06", false), ("2026-07", false), ("2026-08", true)], // 最新は使った
        [("2026-06", false), ("2026-08", false)],                   // 間の月が未回答
        [("2026-07", true), ("2026-08", true)],
        [],
    ])
    func notSuggested(answers: [(String, Bool)]) throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        record(answers, to: subscription)

        #expect(CancelSuggestionDetector.suggestions(for: [subscription]).isEmpty)
    }

    @Test("同じ月は最後の回答を採用する")
    func latestAnswerWins() {
        let checkIns = [
            CheckIn(month: YearMonth("2026-07")!, used: false, answeredAt: date(2026, 8, 1)),
            CheckIn(month: YearMonth("2026-08")!, used: false, answeredAt: date(2026, 9, 1)),
            CheckIn(month: YearMonth("2026-08")!, used: true, answeredAt: date(2026, 9, 2)),
        ]
        #expect(CancelSuggestionDetector.unusedStreak(of: checkIns) == 0)

        let reversed = [
            CheckIn(month: YearMonth("2026-07")!, used: false, answeredAt: date(2026, 8, 1)),
            CheckIn(month: YearMonth("2026-08")!, used: true, answeredAt: date(2026, 9, 1)),
            CheckIn(month: YearMonth("2026-08")!, used: false, answeredAt: date(2026, 9, 2)),
        ]
        #expect(CancelSuggestionDetector.unusedStreak(of: reversed) == 2)
    }

    @Test("解約済みのサブスクは候補にしない")
    func skipsCanceled() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(status: .canceled, canceledAt: date(2026, 9, 1))
        record([("2026-07", false), ("2026-08", false)], to: subscription)

        #expect(CancelSuggestionDetector.suggestions(for: [subscription]).isEmpty)
    }

    @Test("年額換算の大きい順に並べる")
    func sortedByAnnualCost() throws {
        let store = try TestStore()
        let cheap = store.addSubscription(name: "安い", price: 500)
        let yearly = store.addSubscription(name: "年額", price: 24000, cycle: .yearly)
        let expensive = store.addSubscription(name: "高い", price: 2000)
        for subscription in [cheap, yearly, expensive] {
            record([("2026-07", false), ("2026-08", false)], to: subscription)
        }

        let names = CancelSuggestionDetector.suggestions(for: [cheap, yearly, expensive]).map(\.subscription.name)

        #expect(names == ["年額", "高い", "安い"])
    }
}
