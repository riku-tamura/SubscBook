import Foundation
import Observation
import SwiftData

/// サブスクの登録・編集フォーム（④）
@Observable
final class SubscriptionFormViewModel {
    enum Mode {
        case add
        case edit(Subscription)
    }

    /// 入力できる金額の上限（7桁）
    static let maxPrice = 9_999_999

    let mode: Mode

    var name: String {
        didSet { applyPresetCategoryIfNeeded() }
    }
    var category: SubscriptionCategory
    /// 金額の入力文字列（数字のみ）
    private(set) var priceText: String
    var cycle: BillingCycle
    var nextPaymentDate: Date
    var hasTrial: Bool
    var trialEndDate: Date

    /// ユーザーがカテゴリを自分で選んだか。選んだ後は候補からの自動設定をしない。
    private var isCategoryChosenByUser: Bool

    init(mode: Mode, now: Date = .now, calendar: Calendar = .current) {
        self.mode = mode
        switch mode {
        case .add:
            name = ""
            // 候補にないサービス名のまま保存されても、別のジャンルと誤って集計されないように
            category = .other
            priceText = ""
            cycle = .monthly
            nextPaymentDate = calendar.startOfDay(for: now)
            hasTrial = false
            trialEndDate = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: now))!
            isCategoryChosenByUser = false
        case .edit(let subscription):
            name = subscription.name
            category = subscription.category
            priceText = String(subscription.price)
            cycle = subscription.cycle
            nextPaymentDate = subscription.nextPaymentDate
            hasTrial = subscription.trialEndDate != nil
            trialEndDate = subscription.trialEndDate
                ?? calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: now))!
            isCategoryChosenByUser = true
        }
    }

    var editingSubscription: Subscription? {
        if case .edit(let subscription) = mode { subscription } else { nil }
    }

    var isEditing: Bool { editingSubscription != nil }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var price: Int? {
        Int(priceText)
    }

    var suggestions: [ServicePreset] {
        ServicePresetCatalog.suggestions(for: name)
    }

    /// 保存できない理由（保存ボタンが押せないときに表示する）。保存できる場合は nil。
    var validationMessage: String? {
        if trimmedName.isEmpty {
            return "サービス名を入力すると保存できます"
        }
        guard let price else {
            return "金額を入力すると保存できます"
        }
        guard (1...Self.maxPrice).contains(price) else {
            return "金額は1円以上で入力してください"
        }
        return nil
    }

    var canSave: Bool {
        validationMessage == nil
    }

    /// 金額の入力。数字以外（カンマ・全角数字の変換後に残る記号など）は取り除く。
    func updatePriceText(_ text: String) {
        let halfWidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        let digits = String(halfWidth.filter(\.isASCII).filter(\.isNumber).prefix(7))
        // 先頭の0は取り除く（"0980" → "980"）
        let trimmed = digits.drop { $0 == "0" }
        priceText = trimmed.isEmpty && !digits.isEmpty ? "0" : String(trimmed)
    }

    func selectCategory(_ category: SubscriptionCategory) {
        self.category = category
        isCategoryChosenByUser = true
    }

    /// 候補を選ぶ。カテゴリは名前の変更（`applyPresetCategoryIfNeeded`）で、
    /// ユーザーが自分で選んでいなければ候補のものになる。
    func applySuggestion(_ preset: ServicePreset) {
        name = preset.name
    }

    private func applyPresetCategoryIfNeeded() {
        guard !isCategoryChosenByUser, let preset = ServicePresetCatalog.preset(named: name) else { return }
        category = preset.category
    }

    /// 入力内容を保存する。追加時は ModelContext に挿入する。
    /// 次回支払日が過去の場合は、今日以降の支払日まで進めて保存する。
    /// - Parameter isPremium: 保存する時点のサブスク帳プラスの状態。フォームを開いた後にプラスの期限が切れた場合も、
    ///   無料プランの上限を超えて追加しないよう、保存の時点で確かめる。
    @discardableResult
    func save(in context: ModelContext, isPremium: Bool, now: Date = .now, calendar: Calendar = .current) throws -> Subscription {
        guard canSave, let price else { throw FormError.invalidInput }
        if case .add = mode {
            let activeCount = try context.fetchCount(FetchDescriptor(predicate: Subscription.activePredicate))
            guard FreePlan.canAddSubscription(activeCount: activeCount, isPremium: isPremium) else {
                throw FormError.subscriptionLimitReached
            }
        }

        let subscription: Subscription
        switch mode {
        case .add:
            subscription = Subscription(
                name: trimmedName,
                category: category,
                price: price,
                cycle: cycle,
                nextPaymentDate: nextPaymentDate,
                createdAt: now,
                calendar: calendar
            )
            context.insert(subscription)
        case .edit(let existing):
            subscription = existing
            subscription.name = trimmedName
            subscription.category = category
            subscription.price = price
            subscription.cycle = cycle
            if calendar.startOfDay(for: nextPaymentDate) != subscription.nextPaymentDate {
                subscription.setNextPaymentDate(nextPaymentDate, calendar: calendar)
            }
        }

        subscription.setTrialEndDate(hasTrial ? trialEndDate : nil, calendar: calendar)
        subscription.nextPaymentDate = PaymentDateCalculator.advancedPaymentDate(
            from: subscription.nextPaymentDate,
            cycle: subscription.cycle,
            billingDay: subscription.billingDay,
            now: now,
            calendar: calendar
        )
        do {
            try context.save()
        } catch {
            // 保存できなかった追加・変更を取り消す。残すと、もう一度保存したときに二重に追加されたり、
            // 失敗と伝えた変更が、ほかの保存のときに一緒に保存されたりする。
            context.rollback()
            throw error
        }
        return subscription
    }

    enum FormError: Error {
        case invalidInput
        /// 無料プランの上限に達している
        case subscriptionLimitReached
    }
}
