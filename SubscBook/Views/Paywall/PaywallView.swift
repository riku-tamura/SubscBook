import SwiftUI

/// ⑦ ペイウォール
struct PaywallView: View {
    let reason: PaywallReason

    @State private var viewModel = PaywallViewModel()
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    private var plans: [PaywallPlan] {
        viewModel.plans(from: entitlements)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    featureList
                    if entitlements.isPremium {
                        subscribedNotice
                    } else {
                        planSection
                    }
                    legalSection
                }
                .padding()
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task {
                await viewModel.loadProductsIfNeeded(using: entitlements)
            }
            .alert(item: $viewModel.message) { message in
                Alert(
                    title: Text(message.title),
                    message: Text(message.body),
                    dismissButton: .default(Text("OK")) {
                        if message.dismissesPaywall { dismiss() }
                    }
                )
            }
        }
    }

    // MARK: - 見出し・機能

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("サブスク帳プラス")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text(reason.headline)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(reason.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(PremiumFeature.allCases) { feature in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: feature.symbolName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                        Text(feature.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .card()
    }

    // MARK: - プラン

    @ViewBuilder
    private var planSection: some View {
        if plans.isEmpty {
            VStack(spacing: 12) {
                if entitlements.hasProductLoadFailed {
                    Text("プランを読み込めませんでした。通信環境を確認して、もう一度お試しください。")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    Button("再読み込み") {
                        Task { await entitlements.loadProducts() }
                    }
                    .buttonStyle(.bordered)
                } else {
                    ProgressView("プランを読み込んでいます")
                }
            }
            .frame(maxWidth: .infinity)
            .card()
        } else {
            VStack(spacing: 12) {
                let selectedPlan = viewModel.selectedPlan(in: plans)
                ForEach(plans) { plan in
                    PaywallPlanCard(plan: plan, isSelected: plan.id == selectedPlan?.id) {
                        viewModel.selectedPlanID = plan.id
                    }
                }
                purchaseButton(for: selectedPlan)
            }
        }
    }

    @ViewBuilder
    private func purchaseButton(for plan: PaywallPlan?) -> some View {
        if let plan {
            VStack(spacing: 8) {
                Button {
                    Task { await viewModel.purchase(plan, using: entitlements) }
                } label: {
                    Group {
                        if viewModel.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else if let trialText = plan.trialText {
                            Text("\(trialText)で試す")
                        } else {
                            Text("\(plan.priceText)で登録する")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isBusy)

                Text(plan.trialText != nil
                     ? "無料期間の終了後は\(plan.priceText)で自動更新されます。無料期間中に解約すれば料金はかかりません。"
                     : "\(plan.priceText)で自動更新されます。いつでも解約できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
        }
    }

    private var subscribedNotice: some View {
        VStack(spacing: 8) {
            Label("サブスク帳プラスをご利用中です", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Text("すべての機能をお使いいただけます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    // MARK: - 必須表記（7章）

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(plans) { plan in
                    Text("・\(plan.title)：\(plan.priceText)（自動更新）")
                }
                Text("・お支払いは購入の確定時に Apple ID に請求されます。")
                Text("・無料トライアル（年額プランのみ・初回限定）の終了後は、自動的に有料プランに移行します。")
                Text("・サブスクリプションは、現在の期間が終了する24時間前までに解約しない限り、自動的に更新されます。更新の料金は期間終了前の24時間以内に請求されます。")
                Text("・解約はいつでも、「設定」アプリ → 自分の名前（Apple ID）→「サブスクリプション」から行えます。")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { legalLinks }
                VStack(alignment: .leading, spacing: 10) { legalLinks }
            }
            .font(.footnote.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var legalLinks: some View {
        Link("利用規約", destination: AppLinks.termsOfUse)
        NavigationLink("プライバシーポリシー") {
            PrivacyPolicyView()
        }
        Button {
            Task { await viewModel.restore(using: entitlements) }
        } label: {
            if viewModel.isRestoring {
                ProgressView()
            } else {
                Text("購入を復元")
            }
        }
        .disabled(viewModel.isBusy)
    }
}

#if DEBUG
#Preview {
    PaywallView(reason: .subscriptionLimit)
        .previewEnvironment()
}
#endif
