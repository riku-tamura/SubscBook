import Foundation
import Testing
@testable import SubscBook

@Suite("レポートの状態")
struct ReportViewModelTests {
    @Test("レポートに表示する集計をまとめる")
    func summary() throws {
        let store = try TestStore()
        let unused = store.addSubscription(name: "動画A", category: .video, price: 1500)
        unused.recordCheckIn(for: YearMonth("2026-07")!, used: false)
        unused.recordCheckIn(for: YearMonth("2026-08")!, used: false)
        let subscriptions = [
            unused,
            store.addSubscription(name: "動画B", category: .video, price: 500),
            store.addSubscription(name: "年額", category: .cloud, price: 12000, cycle: .yearly),
            store.addSubscription(name: "解約済み", price: 980, status: .canceled, canceledAt: date(2026, 6, 20)),
        ]

        let summary = ReportViewModel().summary(of: subscriptions, now: date(2026, 9, 26))

        #expect(summary.month.key == "2026-09")
        #expect(summary.monthlyTotal == 1500 + 500 + 1000)
        #expect(summary.annualTotal == 18000 + 6000 + 12000)
        #expect(summary.activeCount == 3)
        #expect(summary.breakdown.slices.map(\.category) == [.video, .cloud])
        #expect(summary.cancelSuggestions.map(\.subscription.name) == ["動画A"])
        #expect(summary.duplicateGroups.map(\.category) == [.video])
        #expect(summary.savings.annualSavings == 980 * 12)
    }

    @Test("共有用の画像はサブスク帳プラスで、解約したサブスクがあるときだけ作る")
    func shareImage() {
        let viewModel = ReportViewModel()
        let savings = SavingsSummary(annualSavings: 24_072, realizedSavings: 3_966, canceledCount: 2)
        let noSavings = SavingsSummary(annualSavings: 0, realizedSavings: 0, canceledCount: 0)

        viewModel.updateShareImage(for: savings, isPremium: true)
        #expect(viewModel.shareImage != nil)

        viewModel.updateShareImage(for: savings, isPremium: false)
        #expect(viewModel.shareImage == nil)

        viewModel.updateShareImage(for: noSavings, isPremium: true)
        #expect(viewModel.shareImage == nil)
    }
}
