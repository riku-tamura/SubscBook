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
    }

    @Test("無料は有料機能の詳細を伏せる")
    func freeFacts() throws {
        let store = try TestStore()
        let facts = InsightFactsBuilder.monthly(subscriptions: makeSubscriptions(store), isPremium: false, now: now, calendar: .tokyo)

        #expect(facts.cancelCandidates.isEmpty)
        #expect(facts.hiddenCancelCandidateCount == 1)
        #expect(facts.duplicateCategories.isEmpty)
        #expect(facts.hiddenDuplicateCount == 1)
    }

    @Test("解約候補の理由に渡す文には、数値とかぎ括弧を含めない")
    func reasonPromptHasNoDigits() throws {
        let store = try TestStore()
        let subscriptions = makeSubscriptions(store)
        let suggestion = try #require(CancelSuggestionDetector.suggestions(for: subscriptions).first)
        let reasonFacts = InsightFactsBuilder.cancelReason(for: suggestion, among: subscriptions)
        let prompt = reasonFacts.promptLines.joined()
        #expect(prompt.rangeOfCharacter(from: .decimalDigits) == nil)
        #expect(!prompt.contains("「"))
        #expect(reasonFacts.hasSameCategoryAlternative)
    }

    @Test("事実にない話題（解約候補・重複）に触れた AI の文は使わない")
    func contradictingTerms() {
        let none = MonthlyInsightFacts(
            activeCount: 3, trend: .decreased, cancelCandidates: [], hiddenCancelCandidateCount: 0,
            duplicateCategories: [], hiddenDuplicateCount: 0, canceledThisMonthCount: 1
        )
        #expect(none.contradictingTerms.contains("使っていない"))
        #expect(none.contradictingTerms.contains("重な"))
        #expect(InsightSanitizer.sanitize(
            "今月は減りましたね。使っていないものや重なっているものを確認しましょう。",
            maxLength: 60, forbiddenTerms: none.contradictingTerms
        ) == nil)

        let both = MonthlyInsightFacts(
            activeCount: 3, trend: .unchanged, cancelCandidates: [], hiddenCancelCandidateCount: 1,
            duplicateCategories: [], hiddenDuplicateCount: 1, canceledThisMonthCount: 0
        )
        #expect(both.contradictingTerms.isEmpty)
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
