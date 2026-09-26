import StoreKit
import SwiftUI

/// サブスク帳プラスの状態・管理・購入の復元
struct SettingsPremiumSection: View {
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @State private var isManagingSubscription = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    var body: some View {
        Section {
            if entitlements.isPremium {
                LabeledContent("ご利用中", value: planName)
                if let plan = entitlements.activePlan {
                    if plan.isInFreeTrial {
                        LabeledContent("状態", value: "無料トライアル中")
                    }
                    if let expirationDate = plan.expirationDate {
                        LabeledContent(plan.willAutoRenew ? "次回の更新日" : "有効期限", value: expirationDate.fullDateText)
                    }
                }
                Button("サブスクリプションを管理") {
                    isManagingSubscription = true
                }
            } else {
                Button {
                    router.showPaywall(.settings)
                } label: {
                    HStack {
                        Label("サブスク帳プラスにアップグレード", systemImage: "star.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Button {
                Task { await restore() }
            } label: {
                HStack {
                    Text("購入を復元")
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
        } header: {
            Text("サブスク帳プラス")
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        .alert("購入の復元", isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    private var planName: String {
        guard let plan = entitlements.activePlan else { return "サブスク帳プラス" }
        return plan.isYearly ? "年額プラン" : "月額プラン"
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlements.restore()
            restoreMessage = entitlements.isPremium
                ? "サブスク帳プラスの購入を復元しました。"
                : "この Apple ID でサブスク帳プラスの購入が見つかりませんでした。"
        } catch {
            restoreMessage = "復元できませんでした。時間をおいて、もう一度お試しください。"
        }
    }
}
