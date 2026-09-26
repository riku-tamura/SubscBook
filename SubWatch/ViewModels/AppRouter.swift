import Foundation
import Observation

/// 画面遷移の状態。タブ・シート・ペイウォールの表示をまとめて持つ。
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case home
        case list
        case report
        case settings
    }

    var selectedTab: Tab = .home
    var subscriptionForm: SubscriptionFormRoute?
    var paywall: PaywallReason?
    var isCheckInPresented = false

    func showPaywall(_ reason: PaywallReason) {
        paywall = reason
    }

    /// サブスクの追加。無料プランの上限に達していればペイウォールを出す。
    func requestNewSubscription(activeCount: Int, isPremium: Bool) {
        if FreePlan.canAddSubscription(activeCount: activeCount, isPremium: isPremium) {
            subscriptionForm = .add
        } else {
            showPaywall(.subscriptionLimit)
        }
    }

    func edit(_ subscription: Subscription) {
        subscriptionForm = .edit(subscription)
    }

    /// 通知をタップして起動したときの遷移
    func openNotification(_ kind: PlannedNotification.Kind?) {
        guard let kind else { return }
        let wasPresentingSheet = subscriptionForm != nil || paywall != nil
        subscriptionForm = nil
        paywall = nil
        switch kind {
        case .checkIn:
            selectedTab = .home
            if wasPresentingSheet {
                // シートを閉じるアニメーション中は全画面表示が無視されるため、閉じ終わってから出す
                Task {
                    try? await Task.sleep(for: Self.sheetDismissDelay)
                    isCheckInPresented = true
                }
            } else {
                isCheckInPresented = true
            }
        case .payment, .trial:
            selectedTab = .list
        }
    }

    static let sheetDismissDelay: Duration = .milliseconds(600)
}

enum SubscriptionFormRoute: Identifiable {
    case add
    case edit(Subscription)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let subscription): subscription.id.uuidString
        }
    }
}

/// ペイウォールを表示したきっかけ（7章）
nonisolated enum PaywallReason: Hashable, Identifiable, Sendable {
    /// 6件目のサブスクを登録しようとした
    case subscriptionLimit
    /// ロックされた有料機能をタップした
    case lockedFeature(PremiumFeature)
    /// 設定画面から開いた
    case settings

    var id: Self { self }
}
