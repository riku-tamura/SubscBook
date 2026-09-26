import Foundation
import Observation
import StoreKit

/// サブスク帳プラスの購読状態を一元管理する（7章）。全画面から参照する。
@Observable
final class EntitlementManager {
    /// 加入中のプラン
    struct ActivePlan: Equatable {
        let productID: String
        let expirationDate: Date?
        let willAutoRenew: Bool
        let isInFreeTrial: Bool

        var isYearly: Bool { productID == PremiumProducts.yearly }
    }

    enum RestoreOutcome: Equatable {
        /// 購入が見つかり、プラスが使えるようになった
        case restored
        /// この Apple ID に購入がなかった
        case nothingToRestore
        /// 通信エラーなどで復元できなかった
        case failed
    }

    enum PurchaseOutcome: Equatable {
        case purchased
        /// 承認待ち（ファミリー共有の「承認と購入のリクエスト」など）
        case pending
        case cancelled
    }

    private(set) var hasActiveSubscription = false
    private(set) var activePlan: ActivePlan?
    /// 年額・月額の順
    private(set) var products: [Product] = []
    private(set) var hasProductLoadFailed = false
    /// 導入オファー（年額の1週間無料）を使えるか
    private(set) var isEligibleForIntroOffer = false

    #if DEBUG
    static let debugForcePremiumKey = "debug.forcePremium"
    /// 開発用：購入せずにプラスの画面を確認する
    var debugForcePremium: Bool {
        didSet { UserDefaults.standard.set(debugForcePremium, forKey: Self.debugForcePremiumKey) }
    }
    #endif

    var isPremium: Bool {
        #if DEBUG
        if debugForcePremium { return true }
        #endif
        return hasActiveSubscription
    }

    /// アプリの起動中ずっと監視する
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    /// - Parameter observesTransactions: 起動時から `Transaction.updates` を監視し、購読状態を読み込む
    init(observesTransactions: Bool = true) {
        #if DEBUG
        debugForcePremium = DebugLaunchOptions.forcesPremium
            || UserDefaults.standard.bool(forKey: Self.debugForcePremiumKey)
        #endif
        guard observesTransactions else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            await refreshEntitlements()
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: PremiumProducts.all)
            products = PremiumProducts.all.compactMap { id in loaded.first { $0.id == id } }
            hasProductLoadFailed = products.isEmpty
        } catch {
            hasProductLoadFailed = true
        }
        if let yearly = product(for: PremiumProducts.yearly), let subscription = yearly.subscription,
           subscription.introductoryOffer != nil {
            isEligibleForIntroOffer = await subscription.isEligibleForIntroOffer
        } else {
            isEligibleForIntroOffer = false
        }
    }

    /// `Transaction.currentEntitlements` から購読状態を判定する
    func refreshEntitlements() async {
        var latest: Transaction?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  PremiumProducts.all.contains(transaction.productID),
                  transaction.revocationDate == nil
            else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate < .now { continue }
            if (latest?.expirationDate ?? .distantPast) < (transaction.expirationDate ?? .distantFuture) {
                latest = transaction
            }
        }

        guard let latest else {
            hasActiveSubscription = false
            activePlan = nil
            return
        }
        var willAutoRenew = true
        if let status = await latest.subscriptionStatus, case .verified(let renewalInfo) = status.renewalInfo {
            willAutoRenew = renewalInfo.willAutoRenew
        }
        hasActiveSubscription = true
        activePlan = ActivePlan(
            productID: latest.productID,
            expirationDate: latest.expirationDate,
            willAutoRenew: willAutoRenew,
            isInFreeTrial: latest.offer?.type == .introductory
        )
    }

    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            await transaction.finish()
            await refreshEntitlements()
            await loadProducts()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    /// 購入を復元する（`AppStore.sync()`）
    func restorePurchases() async -> RestoreOutcome {
        do {
            try await AppStore.sync()
        } catch {
            return .failed
        }
        await refreshEntitlements()
        // 開発用のプラス切り替えではなく、実際の購入があるかで判断する
        return hasActiveSubscription ? .restored : .nothingToRestore
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refreshEntitlements()
    }
}
