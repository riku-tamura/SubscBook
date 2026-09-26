import Foundation
import Synchronization
import Testing
@testable import SubWatch

@Suite("AI 出力のチェック")
struct InsightSanitizerTests {
    @Test("前後の空白・括弧を取り除く")
    func trims() {
        #expect(InsightSanitizer.sanitize("  「見直してみませんか？」\n", maxLength: 60) == "見直してみませんか？")
    }

    @Test("数値・金額・英単語を含む出力は使わない", arguments: [
        "月に千円ほど節約できます。1ヶ月使っていません。",
        "年間１２０００円の節約です",
        "円が浮きそうです",
        "少しだけ unused があるみたいです",
        "５割ほど減りました％",
    ])
    func rejectsNumbers(text: String) {
        #expect(InsightSanitizer.sanitize(text, maxLength: 80) == nil)
    }

    @Test("サービス名に含まれる数字・英字は許可する")
    func allowsServiceNames() {
        let text = "Microsoft 365 はしばらく使っていないようです。見直してみませんか？"
        #expect(InsightSanitizer.sanitize(text, maxLength: 80, allowedTerms: ["Microsoft 365", "仕事・ツール"]) == text)
        #expect(InsightSanitizer.sanitize("u-nextを見直しませんか", maxLength: 80, allowedTerms: ["U-NEXT"]) != nil)
    }

    @Test("長すぎる出力・空の出力は使わない")
    func rejectsLength() {
        #expect(InsightSanitizer.sanitize(String(repeating: "あ", count: 80), maxLength: 60) == "\(String(repeating: "あ", count: 80))")
        #expect(InsightSanitizer.sanitize(String(repeating: "あ", count: 81), maxLength: 60) == nil)
        #expect(InsightSanitizer.sanitize("   ", maxLength: 60) == nil)
    }
}

@Suite("AI に渡す事実")
struct InsightFactsTests {
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

    @Test("テンプレート文は事実に合わせて選ぶ")
    func templates() {
        func facts(trend: SpendingTrend = .unchanged, hidden: Int = 0, duplicates: Int = 0, canceled: Int = 0) -> MonthlyInsightFacts {
            MonthlyInsightFacts(
                activeCount: 3, trend: trend, cancelCandidates: [], hiddenCancelCandidateCount: hidden,
                duplicateCategories: [], hiddenDuplicateCount: duplicates, canceledThisMonthCount: canceled
            )
        }
        #expect(TemplateInsightService.monthlyText(for: facts()) == TemplateInsightService.monthlyDefault)
        #expect(TemplateInsightService.monthlyText(for: facts(hidden: 1)).contains("使っていない"))
        #expect(TemplateInsightService.monthlyText(for: facts(duplicates: 1)).contains("重なって"))
        #expect(TemplateInsightService.monthlyText(for: facts(trend: .decreased)).contains("減りました"))
        // テンプレート文も数値を含まない
        for text in [facts(), facts(hidden: 1), facts(duplicates: 1), facts(canceled: 1), facts(trend: .increased)]
            .map(TemplateInsightService.monthlyText(for:)) {
            #expect(InsightSanitizer.sanitize(text, maxLength: 60) == text)
        }
    }
}

/// 呼び出し回数を数えるテスト用の実装
nonisolated final class StubInsightService: InsightService {
    let calls = Mutex(0)
    let isGenerated: Bool
    let delay: Duration

    init(isGenerated: Bool, delay: Duration = .zero) {
        self.isGenerated = isGenerated
        self.delay = delay
    }

    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult {
        calls.withLock { $0 += 1 }
        try? await Task.sleep(for: delay)
        return InsightResult(text: "生成したコメント", isGenerated: isGenerated)
    }

    func cancelReason(for facts: CancelReasonFacts) async -> InsightResult {
        calls.withLock { $0 += 1 }
        return InsightResult(text: "生成した理由", isGenerated: isGenerated)
    }
}

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
        #expect(first == "生成したコメント")
        #expect(second == first)
        #expect(service.calls.withLock { $0 } == 1)

        // 翌月は作り直す
        _ = await provider.monthlyComment(for: facts, now: date(2026, 10, 1), calendar: .tokyo)
        #expect(service.calls.withLock { $0 } == 2)
    }

    @Test("事実が変わったら作り直す")
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

        #expect(results == ["生成したコメント", "生成したコメント"])
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

@Suite("タイムアウト")
struct TimeoutTests {
    @Test("時間内に終われば結果を返す")
    func returnsValue() async throws {
        let value = try await withTimeout(.seconds(1)) { "ok" }
        #expect(value == "ok")
    }

    @Test("時間を超えたら待たずにエラーにする")
    func timesOut() async {
        let start = ContinuousClock.now
        await #expect(throws: InsightTimeoutError.self) {
            try await withTimeout(.milliseconds(100)) {
                // キャンセルに応じない処理でも打ち切れること
                let deadline = ContinuousClock.now + .seconds(3)
                while ContinuousClock.now < deadline {}
                return "late"
            }
        }
        #expect(ContinuousClock.now - start < .seconds(2))
    }
}

@Suite("カテゴリ別の集計")
struct CategoryBreakdownTests {
    @Test("有効なサブスクをカテゴリの定義順に集計し、割合の合計は1")
    func slices() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(category: .music, price: 1000),
            store.addSubscription(category: .video, price: 1500),
            store.addSubscription(category: .video, price: 500),
            store.addSubscription(category: .cloud, price: 12000, cycle: .yearly),
            store.addSubscription(category: .news, price: 3000, status: .canceled, canceledAt: .now),
        ]

        let slices = CategoryBreakdown.slices(of: subscriptions)

        #expect(slices.map(\.category) == [.video, .music, .cloud])
        #expect(slices.map(\.monthlyTotal) == [2000, 1000, 1000])
        #expect(slices.first?.count == 2)
        #expect(abs(slices.reduce(0) { $0 + $1.share } - 1) < 0.0001)
        #expect(CategoryBreakdown.slices(of: []).isEmpty)
    }
}
