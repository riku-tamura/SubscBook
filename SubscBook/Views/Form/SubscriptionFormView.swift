import SwiftData
import SwiftUI

/// ④ サブスクの登録・編集
struct SubscriptionFormView: View {
    /// オンボーディングに埋め込む場合は true。キャンセルボタンを出さず、保存後に閉じない。
    var isEmbedded = false
    /// 保存・解約・削除などでデータが変わった後に呼ばれる
    var onFinish: (() -> Void)?

    @State private var viewModel: SubscriptionFormViewModel
    @State private var isConfirmingCancel = false
    @State private var isConfirmingDelete = false
    @State private var isPaywallPresented = false
    @State private var errorMessage: String?
    /// 削除後に、削除済みのモデルを描画しないためのフラグ
    @State private var isDeleted = false
    /// 金額欄の表示文字列。数字以外を取り除いた結果を必ず表示に反映するため、ViewModel とは別に持つ。
    @State private var priceInput: String
    @FocusState private var focusedField: Field?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementManager.self) private var entitlements

    private enum Field {
        case name
        case price
    }

    init(mode: SubscriptionFormViewModel.Mode, isEmbedded: Bool = false, onFinish: (() -> Void)? = nil) {
        let viewModel = SubscriptionFormViewModel(mode: mode)
        _viewModel = State(initialValue: viewModel)
        _priceInput = State(initialValue: viewModel.priceText)
        self.isEmbedded = isEmbedded
        self.onFinish = onFinish
    }

    var body: some View {
        Form {
            if !isDeleted {
                serviceSection
                paymentSection
                trialSection
                if let subscription = viewModel.editingSubscription {
                    statusSection(subscription)
                    deleteSection
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "サブスクを編集" : "サブスクを登録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEmbedded {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save)
                    .disabled(!viewModel.canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { focusedField = nil }
            }
        }
        .alert("保存できませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(reason: .subscriptionLimit)
        }
    }

    // MARK: - セクション

    private var serviceSection: some View {
        Section("サービス") {
            TextField("サービス名（例：Netflix）", text: $viewModel.name)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .price }

            if focusedField == .name {
                ForEach(viewModel.suggestions) { preset in
                    Button {
                        viewModel.applySuggestion(preset)
                        focusedField = .price
                    } label: {
                        HStack(spacing: 12) {
                            CategoryIcon(name: preset.name, category: preset.category, size: 28)
                            Text(preset.name)
                            Spacer()
                            Text(preset.category.displayName)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                    .accessibilityLabel("候補：\(preset.name)、\(preset.category.displayName)")
                }
            }

            Picker("カテゴリ", selection: Binding(
                get: { viewModel.category },
                set: { viewModel.selectCategory($0) }
            )) {
                ForEach(SubscriptionCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.symbolName)
                        .tag(category)
                }
            }
        }
    }

    private var paymentSection: some View {
        Section {
            HStack {
                Text("金額")
                TextField("0", text: $priceInput)
                .onChange(of: priceInput) { _, newValue in
                    viewModel.updatePriceText(newValue)
                    if priceInput != viewModel.priceText {
                        priceInput = viewModel.priceText
                    }
                }
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .price)
                .accessibilityLabel("金額（円）")
                Text("円")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Picker("支払い周期", selection: $viewModel.cycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.displayName).tag(cycle)
                }
            }
            .pickerStyle(.segmented)

            DatePicker("次回支払日", selection: $viewModel.nextPaymentDate, displayedComponents: .date)
        } header: {
            Text("支払い")
        } footer: {
            Text("過去の日付を入れた場合は、次の支払日に自動で進めます。")
        }
    }

    private var trialSection: some View {
        Section {
            Toggle("無料トライアル中", isOn: $viewModel.hasTrial.animation())
            if viewModel.hasTrial {
                DatePicker("トライアル終了日", selection: $viewModel.trialEndDate, displayedComponents: .date)
            }
        } footer: {
            if viewModel.hasTrial && !entitlements.isPremium {
                Text("トライアル終了前のお知らせはサブスク帳プラスの機能です。")
            }
        }
    }

    private func statusSection(_ subscription: Subscription) -> some View {
        Section {
            if subscription.isActive {
                Button("解約した", systemImage: "scissors") {
                    isConfirmingCancel = true
                }
                .confirmationDialog(
                    "「\(subscription.name)」を解約済みにしますか？",
                    isPresented: $isConfirmingCancel,
                    titleVisibility: .visible
                ) {
                    Button("解約済みにする") { cancelSubscription(subscription) }
                } message: {
                    Text("年間\(subscription.annualCost.yenText)の節約として記録します。")
                }
            } else {
                Button("契約中に戻す", systemImage: "arrow.uturn.backward") {
                    reactivate(subscription)
                }
            }
        } footer: {
            if subscription.isActive {
                Text("このアプリは記録のみを行います。実際の解約手続きは各サービスで行ってください。")
            } else if let canceledAt = subscription.canceledAt {
                Text("\(canceledAt.fullDateText)に解約済み")
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label("削除", systemImage: "trash")
                    .foregroundStyle(.red)
            }
            .confirmationDialog(
                "このサブスクを削除しますか？",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive, action: delete)
            } message: {
                Text("チェックインの記録も削除されます。解約した場合は「解約した」を使うと節約額に反映されます。")
            }
        }
    }

    // MARK: - 操作

    private func save() {
        do {
            try viewModel.save(in: modelContext)
            finish()
        } catch {
            errorMessage = "入力内容を確認してください。"
        }
    }

    private func cancelSubscription(_ subscription: Subscription) {
        applyPendingEdits()
        subscription.cancel()
        persistAndFinish()
    }

    private func reactivate(_ subscription: Subscription) {
        let activeCount = (try? modelContext.fetchCount(FetchDescriptor(predicate: Subscription.activePredicate))) ?? 0
        guard FreePlan.canAddSubscription(activeCount: activeCount, isPremium: entitlements.isPremium) else {
            isPaywallPresented = true
            return
        }
        applyPendingEdits()
        subscription.reactivate()
        persistAndFinish()
    }

    /// 解約・再開の前に、フォームで編集中の内容（金額の修正など）を反映する
    private func applyPendingEdits() {
        guard viewModel.canSave else { return }
        _ = try? viewModel.save(in: modelContext)
    }

    private func delete() {
        guard let subscription = viewModel.editingSubscription else { return }
        isDeleted = true
        modelContext.delete(subscription)
        persistAndFinish()
    }

    private func persistAndFinish() {
        do {
            try modelContext.save()
            finish()
        } catch {
            errorMessage = "データを保存できませんでした。"
        }
    }

    private func finish() {
        onFinish?()
        if !isEmbedded {
            dismiss()
        }
    }
}

#if DEBUG
#Preview("登録") {
    NavigationStack {
        SubscriptionFormView(mode: .add)
    }
    .previewEnvironment()
}
#endif
