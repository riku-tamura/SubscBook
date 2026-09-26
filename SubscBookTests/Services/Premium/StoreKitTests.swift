import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import SubscBook

/// Products.storekit を使って、商品定義と購読状態の判定を確かめる
@Suite("課金（StoreKit）", .serialized)
struct StoreKitTests {
    private let session: SKTestSession

    init() throws {
        session = try SKTestSession(contentsOf: Self.configurationURL())
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    /// リポジトリ直下の Products.storekit（テストファイルの場所から上へたどって探す）
    private static func configurationURL() throws -> URL {
        var directory = URL(filePath: #filePath).deletingLastPathComponent()
        while directory.path() != "/" {
            let candidate = directory.appending(path: "Products.storekit")
            if FileManager.default.fileExists(atPath: candidate.path()) {
                return candidate
            }
            directory.deleteLastPathComponent()
        }
        throw CocoaError(.fileNoSuchFile)
    }

    @Test("月額300円・年額2,400円（1週間無料）が同じグループにある")
    func productDefinitions() async throws {
        let products = try await Product.products(for: PremiumProducts.all)
        let monthly = try #require(products.first { $0.id == PremiumProducts.monthly })
        let yearly = try #require(products.first { $0.id == PremiumProducts.yearly })

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
    func paywallPlans() async throws {
        let entitlements = EntitlementManager(observesTransactions: false)
        await entitlements.loadProducts()

        #expect(entitlements.products.map(\.id) == [PremiumProducts.yearly, PremiumProducts.monthly])
        #expect(entitlements.isEligibleForIntroOffer)
        let plans = entitlements.products.map {
            PaywallPlan(product: $0, isEligibleForIntroOffer: entitlements.isEligibleForIntroOffer)
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
        // テストで作った購入を、アプリの StoreKit テスト環境に残さない
        defer { session.clearTransactions() }
        let entitlements = EntitlementManager(observesTransactions: false)
        await entitlements.loadProducts()
        await entitlements.refreshEntitlements()
        #expect(!entitlements.isPremium || entitlements.debugForcePremium)
        #expect(!entitlements.hasActiveSubscription)

        let monthly = try #require(entitlements.product(for: PremiumProducts.monthly))
        let outcome = try await entitlements.purchase(monthly)

        #expect(outcome == .purchased)
        #expect(entitlements.hasActiveSubscription)
        #expect(entitlements.activePlan?.productID == PremiumProducts.monthly)
        #expect(entitlements.activePlan?.willAutoRenew == true)

        try session.expireSubscription(productIdentifier: PremiumProducts.monthly)
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
        // テストで作った購入を、アプリの StoreKit テスト環境に残さない
        defer { session.clearTransactions() }
        let entitlements = EntitlementManager(observesTransactions: false)
        await entitlements.loadProducts()
        let yearly = try #require(entitlements.product(for: PremiumProducts.yearly))

        _ = try await entitlements.purchase(yearly)

        #expect(entitlements.hasActiveSubscription)
        #expect(entitlements.activePlan?.isYearly == true)
        #expect(entitlements.activePlan?.isInFreeTrial == true)
        #expect(!entitlements.isEligibleForIntroOffer)
    }

    @Test("ペイウォールで購入すると完了メッセージを出し、プラスになる")
    func paywallPurchase() async throws {
        // テストで作った購入を、アプリの StoreKit テスト環境に残さない
        defer { session.clearTransactions() }
        let entitlements = EntitlementManager(observesTransactions: false)
        let viewModel = PaywallViewModel()
        await viewModel.loadProductsIfNeeded(using: entitlements)
        let plan = try #require(viewModel.selectedPlan(in: viewModel.plans(from: entitlements)))
        #expect(plan.id == PremiumProducts.yearly)

        await viewModel.purchase(plan, using: entitlements)

        #expect(viewModel.message?.title == "ありがとうございます")
        #expect(viewModel.message?.dismissesPaywall == true)
        #expect(entitlements.hasActiveSubscription)
        #expect(!viewModel.isBusy)
    }
}
