import Foundation
import Testing
@testable import SubscBook

@Suite("ホームの状態")
struct HomeViewModelTests {
    private func makeInsights(isGenerated: Bool = true) -> InsightProvider {
        InsightProvider(
            service: StubInsightService(isGenerated: isGenerated),
            cache: InsightCache(defaults: UserDefaults(suiteName: "HomeViewModelTests.\(UUID().uuidString)")!),
            availability: .available
        )
    }

    private func makeSubscriptions(_ store: TestStore) -> [Subscription] {
        let unused = store.addSubscription(name: "未使用")
        unused.recordCheckIn(for: YearMonth("2026-07")!, used: false)
        unused.recordCheckIn(for: YearMonth("2026-08")!, used: false)
        return [unused, store.addSubscription(name: "使用中")]
    }

    @Test("解約候補の理由は、サブスク帳プラスのときだけ作る")
    func cancelReasonFactsOnlyForPremium() throws {
        let store = try TestStore()
        let subscriptions = makeSubscriptions(store)
        let viewModel = HomeViewModel()
        let summary = viewModel.summary(of: subscriptions, now: date(2026, 9, 26))

        #expect(viewModel.cancelReasonFacts(of: subscriptions, summary: summary, isPremium: false).isEmpty)
        #expect(viewModel.cancelReasonFacts(of: subscriptions, summary: summary, isPremium: true).map(\.name) == ["未使用"])
    }

    @Test("AI のひとことと解約理由を読み込む")
    func loadsInsights() async throws {
        let store = try TestStore()
        let subscriptions = makeSubscriptions(store)
        let viewModel = HomeViewModel()
        let summary = viewModel.summary(of: subscriptions, now: date(2026, 9, 26))
        let insights = makeInsights()

        await viewModel.loadComment(
            for: viewModel.insightFacts(of: subscriptions, summary: summary, isPremium: true),
            using: insights
        )
        let reasonFacts = viewModel.cancelReasonFacts(of: subscriptions, summary: summary, isPremium: true)
        await viewModel.loadCancelReasons(for: reasonFacts, using: insights)

        #expect(viewModel.comment == "生成したコメント")
        #expect(viewModel.cancelReasons == [subscriptions[0].id: "生成した理由"])
    }
}
