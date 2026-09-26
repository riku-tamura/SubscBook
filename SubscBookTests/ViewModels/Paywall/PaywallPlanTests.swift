import Foundation
import StoreKit
import Testing
@testable import SubscBook

@Suite("ペイウォールのプラン表示")
struct PaywallPlanTests {
    @Test("期間の表記")
    func periodText() {
        #expect(PaywallPlan.periodText(value: 1, unit: .week) == "1週間")
        #expect(PaywallPlan.periodText(value: 3, unit: .day) == "3日間")
        #expect(PaywallPlan.periodText(value: 1, unit: .month) == "1ヶ月")
        #expect(PaywallPlan.periodText(value: 1, unit: .year) == "1年")
    }

    @Test("金額と周期の表記")
    func priceText() {
        let yearly = PaywallPlan(id: PremiumProducts.yearly, isYearly: true, displayPrice: "¥2,400", perMonthText: "月あたり¥200", trialText: "1週間無料")
        #expect(yearly.title == "年額プラン")
        #expect(yearly.priceText == "¥2,400/年")

        let monthly = PaywallPlan(id: PremiumProducts.monthly, isYearly: false, displayPrice: "¥300", perMonthText: nil, trialText: nil)
        #expect(monthly.title == "月額プラン")
        #expect(monthly.priceText == "¥300/月")
    }
}
