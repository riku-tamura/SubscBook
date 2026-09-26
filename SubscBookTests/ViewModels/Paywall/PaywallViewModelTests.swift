import Foundation
import Testing
@testable import SubscBook

@Suite("ペイウォールの状態")
struct PaywallViewModelTests {
    private let plans = [
        PaywallPlan(id: PremiumProducts.yearly, isYearly: true, displayPrice: "¥2,400", perMonthText: nil, trialText: nil),
        PaywallPlan(id: PremiumProducts.monthly, isYearly: false, displayPrice: "¥300", perMonthText: nil, trialText: nil),
    ]

    @Test("はじめは年額プランを選んでいる")
    func selectsYearlyByDefault() {
        let viewModel = PaywallViewModel()
        #expect(viewModel.selectedPlan(in: plans)?.id == PremiumProducts.yearly)
        #expect(!viewModel.isBusy)
    }

    @Test("選んだプランが一覧にない場合は先頭のプラン")
    func fallsBackToFirstPlan() {
        let viewModel = PaywallViewModel()
        viewModel.selectedPlanID = PremiumProducts.monthly
        #expect(viewModel.selectedPlan(in: plans)?.id == PremiumProducts.monthly)
        #expect(viewModel.selectedPlan(in: Array(plans.prefix(1)))?.id == PremiumProducts.yearly)
        #expect(viewModel.selectedPlan(in: []) == nil)
    }
}
