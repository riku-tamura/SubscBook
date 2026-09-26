import Foundation
import Testing
@testable import SubscBook

@Suite("一覧の状態")
struct SubscriptionListViewModelTests {
    @Test("無料プランの残り件数を案内する", arguments: [
        (3, "あと2件"),
        (4, "あと1件"),
        (5, "上限（5件）に達しました"),
        (7, "上限（5件）に達しました"),
    ])
    func freePlanMessage(activeCount: Int, expected: String) {
        #expect(SubscriptionListViewModel().freePlanMessage(activeCount: activeCount).contains(expected))
    }

    @Test("解約済みのセクションは閉じた状態から開閉できる")
    func toggleCanceledSection() {
        let viewModel = SubscriptionListViewModel()
        #expect(!viewModel.isCanceledExpanded)
        viewModel.toggleCanceledSection()
        #expect(viewModel.isCanceledExpanded)
        viewModel.toggleCanceledSection()
        #expect(!viewModel.isCanceledExpanded)
    }
}
