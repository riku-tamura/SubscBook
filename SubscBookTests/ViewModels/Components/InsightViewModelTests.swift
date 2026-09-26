import Foundation
import Testing
@testable import SubscBook

@Suite("AI コメントの読み込み")
struct InsightViewModelTests {
    private func makeInsights() -> InsightProvider {
        InsightProvider(
            service: StubInsightService(isGenerated: true),
            cache: InsightCache(defaults: UserDefaults(suiteName: "InsightViewModelTests.\(UUID().uuidString)")!),
            availability: .available
        )
    }

    private func reasonFacts(for id: UUID, name: String) -> CancelReasonFacts {
        CancelReasonFacts(
            subscriptionID: id, name: name, categoryName: "動画", unusedMonths: 2,
            cycle: .monthly, hasSameCategoryAlternative: false
        )
    }

    @Test("解約理由を読み込み、候補から外れたサブスクの理由は消す")
    func cancelReasons() async {
        let viewModel = InsightViewModel()
        let insights = makeInsights()
        let first = UUID()
        let second = UUID()

        await viewModel.loadCancelReasons(
            for: [reasonFacts(for: first, name: "A"), reasonFacts(for: second, name: "B")],
            using: insights
        )
        #expect(Set(viewModel.cancelReasons.keys) == [first, second])

        await viewModel.loadCancelReasons(for: [reasonFacts(for: second, name: "B")], using: insights)
        #expect(Set(viewModel.cancelReasons.keys) == [second])

        await viewModel.loadCancelReasons(for: [], using: insights)
        #expect(viewModel.cancelReasons.isEmpty)
    }

    @Test("解約理由の事実はサブスク帳プラスのときだけ作る")
    func cancelReasonFactsOnlyForPremium() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(name: "未使用")
        subscription.recordCheckIn(for: YearMonth("2026-07")!, used: false)
        subscription.recordCheckIn(for: YearMonth("2026-08")!, used: false)
        let suggestions = CancelSuggestionDetector.suggestions(for: [subscription])
        let viewModel = InsightViewModel()

        #expect(viewModel.cancelReasonFacts(of: [subscription], suggestions: suggestions, isPremium: false).isEmpty)
        #expect(viewModel.cancelReasonFacts(of: [subscription], suggestions: suggestions, isPremium: true).map(\.name) == ["未使用"])
    }
}
