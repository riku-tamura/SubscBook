import StoreKit
import SwiftUI

/// サブスク帳プラスの状態・管理・購入の復元
struct SettingsPremiumSection: View {
    let viewModel: SettingsViewModel
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @State private var isManagingSubscription = false

    var body: some View {
        Section {
            if entitlements.isPremium {
                LabeledContent("ご利用中", value: viewModel.planName(of: entitlements))
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
                Task { await viewModel.restorePurchases(using: entitlements) }
            } label: {
                HStack {
                    Text("購入を復元")
                    if viewModel.isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isRestoring)
        } header: {
            Text("サブスク帳プラス")
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        .alert("購入の復元", isPresented: Binding(
            get: { viewModel.restoreMessage != nil },
            set: { if !$0 { viewModel.restoreMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(viewModel.restoreMessage ?? "")
        }
    }
}
