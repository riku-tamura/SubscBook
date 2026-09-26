import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import SubWatch

/// Products.storekit を使って、商品定義と購読状態の判定を確かめる
@Suite("課金（StoreKit）", .serialized)
struct StoreKitTests {
    private let session: SKTestSession

    init() throws {
        let configuration = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Products.storekit")
        session = try SKTestSession(contentsOf: configuration)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    @Test("月額300円・年額2,400円（1週間無料）が同じグループにある")
    func productDefinitions() async throws {
        let products = try await Product.products(for: StoreProducts.all)
        let monthly = try #require(products.first { $0.id == StoreProducts.monthly })
        let yearly = try #require(products.first { $0.id == StoreProducts.yearly })

        #expect(monthly.price == 300)
        #expect(yearly.price == 2400)
        #expect(monthly.subscription?.subscriptionPeriod.unit == .month)
        #expect(monthly.subscription?.subscriptionPeriod.value == 1)
        #expect(yearly.subscription?.subscriptionPeriod.unit == .year)
        #expect(yearly.subscription?.subscriptionPeriod.value == 1)
        #expect(monthly.subscription?.subscriptionGroupID == yearly.subscription?.subscriptionGroupID)
        #expect(monthly.subscription?.introductoryOffer == nil)
        let offer = try #require(yearly.subscription?.introductoryOffer)
        #expect(offer.paymentMode == .freeTrial)
        #expect(offer.period.unit == .week)
        #expect(offer.period.value == 1)
    }

    @Test("ペイウォールの表示：年額は月あたりの金額と無料期間を併記する")
    func planOptions() async throws {
        let entitlements = EntitlementManager(observesTransactions: false)
        await entitlements.loadProducts()

        #expect(entitlements.products.map(\.id) == [StoreProducts.yearly, StoreProducts.monthly])
        #expect(entitlements.isEligibleForIntroOffer)
        let plans = entitlements.products.map {
            PlanOption(product: $0, isEligibleForIntroOffer: entitlements.isEligibleForIntroOffer)
        }
        let yearly = try #require(plans.first)
        #expect(yearly.isYearly)
        #expect(yearly.perMonthText?.contains("200") == true)
        #expect(yearly.trialText == "1週間無料")
        #expect(yearly.priceText.contains("2,400"))
        let monthly = try #require(plans.last)
        #expect(!monthly.isYearly)
        #expect(monthly.perMonthText == nil)
        #expect(monthly.trialText == nil)
    }

    @Test("購入するとプラスになり、期限が切れると無料に戻る")
    func purchaseAndExpire() async throws {
        let entitlements = EntitlementManager(observesTransactions: false)
        await entitlements.loadProducts()
        await entitlements.refreshEntitlements()
        #expect(!entitlements.isPremium || entitlements.debugForcePremium)
        #expect(!entitlements.hasActiveSubscription)

        let monthly = try #require(entitlements.product(for: StoreProducts.monthly))
        let outcome = try await entitlements.purchase(monthly)

        #expect(outcome == .purchased)
        #expect(entitlements.hasActiveSubscription)
        #expect(entitlements.activePlan?.productID == StoreProducts.monthly)
        #expect(entitlements.activePlan?.willAutoRenew == true)

        try session.expireSubscription(productIdentifier: StoreProducts.monthly)
        // テストセッションでの期限切れは少し遅れて反映される
        for _ in 0..<30 where entitlements.hasActiveSubscription {
            try await Task.sleep(for: .milliseconds(100))
            await entitlements.refreshEntitlements()
        }
        #expect(!entitlements.hasActiveSubscription)
        #expect(entitlements.activePlan == nil)
    }

    @Test("年額の無料トライアル中は、トライアル中として扱い、以降の導入オファーは使えない")
    func yearlyTrial() async throws {
        let entitlements = EntitlementManager(observesTransactions: false)
        await entitlements.loadProducts()
        let yearly = try #require(entitlements.product(for: StoreProducts.yearly))

        _ = try await entitlements.purchase(yearly)

        #expect(entitlements.hasActiveSubscription)
        #expect(entitlements.activePlan?.isYearly == true)
        #expect(entitlements.activePlan?.isInFreeTrial == true)
        #expect(!entitlements.isEligibleForIntroOffer)
    }

    @Test("期間の表記")
    func periodText() {
        #expect(PlanOption.periodText(value: 1, unit: .week) == "1週間")
        #expect(PlanOption.periodText(value: 3, unit: .day) == "3日間")
        #expect(PlanOption.periodText(value: 1, unit: .month) == "1ヶ月")
        #expect(PlanOption.periodText(value: 1, unit: .year) == "1年")
    }
}
