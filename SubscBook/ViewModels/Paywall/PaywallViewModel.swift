import Foundation
import Observation

/// ⑦ ペイウォールの状態と操作
@Observable
final class PaywallViewModel {
    var selectedPlanID = PremiumProducts.yearly
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    /// 購入・復元の結果（アラートで表示する）
    var message: PaywallMessage?

    /// 購入・復元の処理中は、ほかの操作を受け付けない
    var isBusy: Bool { isPurchasing || isRestoring }

    /// 表示するプラン（年額・月額の順）
    func plans(from entitlements: EntitlementManager) -> [PaywallPlan] {
        let plans = entitlements.products.map {
            PaywallPlan(product: $0, isEligibleForIntroOffer: entitlements.isEligibleForIntroOffer)
        }
        #if DEBUG
        if plans.isEmpty && DebugLaunchOptions.usesSamplePlans {
            return PaywallPlan.samples
        }
        #endif
        return plans
    }

    func selectedPlan(in plans: [PaywallPlan]) -> PaywallPlan? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    func loadProductsIfNeeded(using entitlements: EntitlementManager) async {
        if entitlements.products.isEmpty {
            await entitlements.loadProducts()
        }
    }

    func purchase(_ plan: PaywallPlan, using entitlements: EntitlementManager) async {
        guard let product = entitlements.product(for: plan.id) else {
            message = PaywallMessage(title: "購入できません", body: "プランの情報を読み込めませんでした。")
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await entitlements.purchase(product) {
            case .purchased:
                message = PaywallMessage(
                    title: "ありがとうございます",
                    body: "サブスク帳プラスのすべての機能が使えるようになりました。",
                    dismissesPaywall: true
                )
            case .pending:
                message = PaywallMessage(
                    title: "承認を待っています",
                    body: "購入が承認されると、サブスク帳プラスが使えるようになります。",
                    dismissesPaywall: true
                )
            case .cancelled:
                break
            }
        } catch {
            message = PaywallMessage(title: "購入を完了できませんでした", body: "時間をおいて、もう一度お試しください。")
        }
    }

    func restore(using entitlements: EntitlementManager) async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlements.restore()
            message = entitlements.isPremium
                ? PaywallMessage(title: "購入を復元しました", body: "サブスク帳プラスが使えるようになりました。", dismissesPaywall: true)
                : PaywallMessage(title: "復元できる購入がありません", body: "この Apple ID でサブスク帳プラスの購入が見つかりませんでした。")
        } catch {
            message = PaywallMessage(title: "復元できませんでした", body: "時間をおいて、もう一度お試しください。")
        }
    }
}
