import Foundation
import Testing
@testable import SubscBook

@Suite("オンボーディングの状態")
struct OnboardingViewModelTests {
    @Test("価値の説明から始まり、ボタンで次のページへ進む")
    func advance() {
        let viewModel = OnboardingViewModel()
        #expect(viewModel.page == .value)
        #expect(!viewModel.isRequestingNotifications)

        viewModel.advance(to: .notifications)
        #expect(viewModel.page == .notifications)
        viewModel.advance(to: .firstSubscription)
        #expect(viewModel.page == .firstSubscription)
    }
}
