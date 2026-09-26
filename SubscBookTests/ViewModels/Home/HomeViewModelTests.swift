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

    @Test("AI のひとことと解約理由を読み込む")
    func loadsInsights() async throws {
        let store = try TestStore()
        let subscriptions = makeSubscriptions(store)
        let viewModel = HomeViewModel()
        let summary = viewModel.summary(of: subscriptions, now: date(2026, 9, 26))
        let insights = makeInsights()

        await viewModel.insight.loadComment(
            for: viewModel.insightFacts(of: subscriptions, summary: summary, isPremium: true),
            using: insights
        )
        let reasonFacts = viewModel.cancelReasonFacts(of: subscriptions, summary: summary, isPremium: true)
        await viewModel.insight.loadCancelReasons(for: reasonFacts, using: insights)

        #expect(viewModel.insight.comment == "生成したコメント")
        #expect(viewModel.insight.cancelReasons == [subscriptions[0].id: "生成した理由"])
    }
}
