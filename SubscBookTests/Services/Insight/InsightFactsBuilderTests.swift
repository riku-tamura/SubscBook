import Foundation
import Testing
@testable import SubscBook

@Suite("AI に渡す事実")
struct InsightFactsBuilderTests {
    private let now = date(2026, 9, 26)

    private func makeSubscriptions(_ store: TestStore) -> [Subscription] {
        let unused = store.addSubscription(name: "U-NEXT", category: .video, price: 2189, createdAt: date(2026, 1, 1))
        unused.recordCheckIn(for: YearMonth("2026-07")!, used: false)
        unused.recordCheckIn(for: YearMonth("2026-08")!, used: false)
        return [
            unused,
            store.addSubscription(name: "Netflix", category: .video, price: 1590, createdAt: date(2026, 1, 1)),
            store.addSubscription(name: "Spotify", category: .music, price: 1080, createdAt: date(2026, 9, 10)),
            store.addSubscription(name: "Hulu", category: .video, price: 1026, status: .canceled,
                                  canceledAt: date(2026, 9, 5), createdAt: date(2026, 1, 1)),
        ]
    }

    @Test("プラスは解約候補・重複の名前を渡す")
    func premiumFacts() throws {
        let store = try TestStore()
        let facts = InsightFactsBuilder.monthly(subscriptions: makeSubscriptions(store), isPremium: true, now: now, calendar: .tokyo)

        #expect(facts.activeCount == 3)
        #expect(facts.cancelCandidates.map(\.name) == ["U-NEXT"])
        #expect(facts.duplicateCategories.map(\.categoryName) == ["動画"])
        #expect(facts.canceledThisMonthCount == 1)
        #expect(facts.promptLines.contains("- U-NEXT をしばらく使っていない"))
        #expect(facts.promptLines.contains("- 動画のサブスクが重なっている"))
        #expect(facts.promptLines.contains("- 今月サブスクを解約した"))
    }

    @Test("無料は有料機能の詳細を伏せる")
    func freeFacts() throws {
        let store = try TestStore()
        let facts = InsightFactsBuilder.monthly(subscriptions: makeSubscriptions(store), isPremium: false, now: now, calendar: .tokyo)

        #expect(facts.cancelCandidates.isEmpty)
        #expect(facts.hiddenCancelCandidateCount == 1)
        #expect(facts.duplicateCategories.isEmpty)
        #expect(facts.hiddenDuplicateCount == 1)
        let prompt = facts.promptLines.joined()
        #expect(!prompt.contains("U-NEXT"))
        #expect(!prompt.contains("動画"))
    }

    @Test("AI に渡す文には数値を含めない")
    func promptHasNoDigits() throws {
        let store = try TestStore()
        let subscriptions = makeSubscriptions(store)
        for isPremium in [true, false] {
            let facts = InsightFactsBuilder.monthly(subscriptions: subscriptions, isPremium: isPremium, now: now, calendar: .tokyo)
            #expect(facts.promptLines.joined().rangeOfCharacter(from: .decimalDigits) == nil)
        }
        let suggestion = try #require(CancelSuggestionDetector.suggestions(for: subscriptions).first)
        let reasonFacts = InsightFactsBuilder.cancelReason(for: suggestion, among: subscriptions)
        #expect(reasonFacts.promptLines.joined().rangeOfCharacter(from: .decimalDigits) == nil)
        #expect(reasonFacts.hasSameCategoryAlternative)
    }

    @Test("前月比：前月末に契約中だったサブスクの月額と比べる")
    func trend() throws {
        let store = try TestStore()
        let old = store.addSubscription(price: 1000, createdAt: date(2026, 1, 1))
        #expect(InsightFactsBuilder.trend(of: [old], now: now, calendar: .tokyo) == .unchanged)

        let added = store.addSubscription(price: 500, createdAt: date(2026, 9, 10))
        #expect(InsightFactsBuilder.trend(of: [old, added], now: now, calendar: .tokyo) == .increased)

        let canceled = store.addSubscription(price: 800, status: .canceled, canceledAt: date(2026, 9, 3), createdAt: date(2026, 2, 1))
        #expect(InsightFactsBuilder.trend(of: [old, canceled], now: now, calendar: .tokyo) == .decreased)

        let newOnly = store.addSubscription(createdAt: date(2026, 9, 2))
        #expect(InsightFactsBuilder.trend(of: [newOnly], now: now, calendar: .tokyo) == .unknown)
    }
}
