import Foundation
import Synchronization
import Testing
@testable import SubscBook

@Suite("AI コメントのキャッシュ")
struct InsightProviderTests {
    private let facts = MonthlyInsightFacts(
        activeCount: 3, trend: .unchanged, cancelCandidates: [], hiddenCancelCandidateCount: 0,
        duplicateCategories: [], hiddenDuplicateCount: 0, canceledThisMonthCount: 0
    )

    private func makeCache() -> InsightCache {
        let defaults = UserDefaults(suiteName: "InsightProviderTests.\(UUID().uuidString)")!
        return InsightCache(defaults: defaults)
    }

    @Test("同じ月・同じ事実では生成しない")
    func cachesPerMonth() async {
        let service = StubInsightService(isGenerated: true)
        let provider = InsightProvider(service: service, cache: makeCache(), availability: .available)

        let first = await provider.monthlyComment(for: facts, now: date(2026, 9, 1), calendar: .tokyo)
        let second = await provider.monthlyComment(for: facts, now: date(2026, 9, 30), calendar: .tokyo)
        #expect(first.text == "生成したコメント")
        #expect(first.isGenerated)
        #expect(second == first)
        #expect(service.calls.withLock { $0 } == 1)

        // 翌月は作り直す
        _ = await provider.monthlyComment(for: facts, now: date(2026, 10, 1), calendar: .tokyo)
        #expect(service.calls.withLock { $0 } == 2)
    }

    @Test("伝える内容が変わったら作り直す")
    func regeneratesWhenFactsChange() async {
        let service = StubInsightService(isGenerated: true)
        let provider = InsightProvider(service: service, cache: makeCache(), availability: .available)
        let changed = MonthlyInsightFacts(
            activeCount: 3, trend: .increased, cancelCandidates: [], hiddenCancelCandidateCount: 0,
            duplicateCategories: [], hiddenDuplicateCount: 0, canceledThisMonthCount: 0
        )

        _ = await provider.monthlyComment(for: facts, now: date(2026, 9, 1), calendar: .tokyo)
        _ = await provider.monthlyComment(for: changed, now: date(2026, 9, 1), calendar: .tokyo)
        #expect(service.calls.withLock { $0 } == 2)
    }

    @Test("事実が変わっても、伝える内容（AI が言い換える元の文）が同じなら再利用する")
    func reusesWhenMessageIsSame() async {
        let service = StubInsightService(isGenerated: true)
        let provider = InsightProvider(service: service, cache: makeCache(), availability: .available)
        // 解約候補があるときは、支払いの増減によらず解約候補について伝える
        let unchanged = MonthlyInsightFacts(
            activeCount: 3, trend: .unchanged, cancelCandidates: [], hiddenCancelCandidateCount: 1,
            duplicateCategories: [], hiddenDuplicateCount: 0, canceledThisMonthCount: 0
        )
        let increased = MonthlyInsightFacts(
            activeCount: 4, trend: .increased, cancelCandidates: [], hiddenCancelCandidateCount: 1,
            duplicateCategories: [], hiddenDuplicateCount: 0, canceledThisMonthCount: 0
        )

        _ = await provider.monthlyComment(for: unchanged, now: date(2026, 9, 1), calendar: .tokyo)
        _ = await provider.monthlyComment(for: increased, now: date(2026, 9, 1), calendar: .tokyo)
        #expect(service.calls.withLock { $0 } == 1)
    }

    @Test("無料・プラスで事実が切り替わっても、今月生成したものは再利用する")
    func keepsMultipleEntriesPerMonth() async {
        let service = StubInsightService(isGenerated: true)
        let provider = InsightProvider(service: service, cache: makeCache(), availability: .available)
        let premium = MonthlyInsightFacts(
            activeCount: 3, trend: .unchanged, cancelCandidates: [.init(name: "U-NEXT", unusedMonths: 2)],
            hiddenCancelCandidateCount: 0, duplicateCategories: [], hiddenDuplicateCount: 0, canceledThisMonthCount: 0
        )

        for _ in 0..<2 {
            _ = await provider.monthlyComment(for: facts, now: date(2026, 9, 1), calendar: .tokyo)
            _ = await provider.monthlyComment(for: premium, now: date(2026, 9, 1), calendar: .tokyo)
        }
        #expect(service.calls.withLock { $0 } == 2)
    }

    @Test("定型のコメント（生成失敗）は、AI で作ったものとして扱わない")
    func fallbackIsNotGenerated() async {
        let service = StubInsightService(isGenerated: false)
        let provider = InsightProvider(service: service, cache: makeCache(), availability: .available)

        let result = await provider.monthlyComment(for: facts, now: date(2026, 9, 1), calendar: .tokyo)
        #expect(!result.isGenerated)
    }

    @Test("テンプレート文（生成失敗）はキャッシュしない")
    func doesNotCacheFallback() async {
        let service = StubInsightService(isGenerated: false)
        let provider = InsightProvider(service: service, cache: makeCache(), availability: .available)

        _ = await provider.monthlyComment(for: facts, now: date(2026, 9, 1), calendar: .tokyo)
        _ = await provider.monthlyComment(for: facts, now: date(2026, 9, 1), calendar: .tokyo)
        #expect(service.calls.withLock { $0 } == 2)
    }

    @Test("同時に求められても生成は1回")
    func deduplicatesConcurrentRequests() async {
        let service = StubInsightService(isGenerated: true, delay: .milliseconds(100))
        let provider = InsightProvider(service: service, cache: makeCache(), availability: .available)

        async let first = provider.monthlyComment(for: facts, now: date(2026, 9, 1), calendar: .tokyo)
        async let second = provider.monthlyComment(for: facts, now: date(2026, 9, 1), calendar: .tokyo)
        let results = await [first, second]

        #expect(results.map(\.text) == ["生成したコメント", "生成したコメント"])
        #expect(service.calls.withLock { $0 } == 1)
    }

    @Test("解約理由も月・サブスク・事実ごとにキャッシュする")
    func cachesCancelReason() async {
        let service = StubInsightService(isGenerated: true)
        let provider = InsightProvider(service: service, cache: makeCache(), availability: .available)
        let reasonFacts = CancelReasonFacts(
            subscriptionID: UUID(), name: "U-NEXT", categoryName: "動画", unusedMonths: 2,
            cycle: .monthly, hasSameCategoryAlternative: false
        )

        _ = await provider.cancelReason(for: reasonFacts, now: date(2026, 9, 1), calendar: .tokyo)
        _ = await provider.cancelReason(for: reasonFacts, now: date(2026, 9, 2), calendar: .tokyo)
        #expect(service.calls.withLock { $0 } == 1)
    }
}
