import StoreKit
import SwiftUI

/// ⑦ ペイウォール
struct PaywallView: View {
    let reason: PaywallReason

    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlanID = StoreProducts.yearly
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var message: PaywallMessage?

    private var plans: [PlanOption] {
        let plans = entitlements.products.map {
            PlanOption(product: $0, isEligibleForIntroOffer: entitlements.isEligibleForIntroOffer)
        }
        #if DEBUG
        if plans.isEmpty && DebugLaunchOptions.usesSamplePlans {
            return PlanOption.samples
        }
        #endif
        return plans
    }

    private var selectedPlan: PlanOption? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    var body: some View {
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
                if entitlements.products.isEmpty {
                    await entitlements.loadProducts()
                }
            }
            .alert(item: $message) { message in
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
            Image(systemName: "binoculars.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("見張り番プラス")
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
                ForEach(plans) { plan in
                    PlanCard(plan: plan, isSelected: plan.id == selectedPlan?.id) {
                        selectedPlanID = plan.id
                    }
                }
                purchaseButton
            }
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if let plan = selectedPlan {
            VStack(spacing: 8) {
                Button {
                    Task { await purchase(plan) }
                } label: {
                    Group {
                        if isPurchasing {
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
                .disabled(isPurchasing || isRestoring)

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
            Label("見張り番プラスをご利用中です", systemImage: "checkmark.seal.fill")
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
            Task { await restore() }
        } label: {
            if isRestoring {
                ProgressView()
            } else {
                Text("購入を復元")
            }
        }
        .disabled(isPurchasing || isRestoring)
    }

    // MARK: - 操作

    private func purchase(_ plan: PlanOption) async {
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
                    body: "見張り番プラスのすべての機能が使えるようになりました。",
                    dismissesPaywall: true
                )
            case .pending:
                message = PaywallMessage(
                    title: "承認を待っています",
                    body: "購入が承認されると、見張り番プラスが使えるようになります。",
                    dismissesPaywall: true
                )
            case .cancelled:
                break
            }
        } catch {
            message = PaywallMessage(title: "購入を完了できませんでした", body: "時間をおいて、もう一度お試しください。")
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlements.restore()
            message = entitlements.isPremium
                ? PaywallMessage(title: "購入を復元しました", body: "見張り番プラスが使えるようになりました。", dismissesPaywall: true)
                : PaywallMessage(title: "復元できる購入がありません", body: "この Apple ID で見張り番プラスの購入が見つかりませんでした。")
        } catch {
            message = PaywallMessage(title: "復元できませんでした", body: "時間をおいて、もう一度お試しください。")
        }
    }
}

/// プランの選択カード。年額は「いちばんお得」として大きく表示する。
private struct PlanCard: View {
    let plan: PlanOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    if plan.isYearly {
                        Text("いちばんお得")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor, in: .capsule)
                            .fixedSize()
                    }
                    Text(plan.title)
                        .font(plan.isYearly ? .title3.weight(.bold) : .headline)
                    if let perMonthText = plan.perMonthText {
                        Text(perMonthText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    if let trialText = plan.trialText {
                        Text("最初の\(trialText)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Text(plan.priceText)
                    .font(plan.isYearly ? .title3.weight(.bold) : .headline)
                    .monospacedDigit()
            }
            .padding(plan.isYearly ? 20 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.accentColor : Color(.separator), lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview {
    PaywallView(reason: .subscriptionLimit)
        .previewEnvironment()
}
