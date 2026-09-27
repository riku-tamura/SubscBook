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

    /// 閉じ終わってから出す画面。閉じるアニメーション中に新しいシートや全画面表示を出すと無視されるため、
    /// MainTabView の onDismiss（`didDismissPresentation`）で出す。
    enum PendingPresentation: Equatable {
        case paywall(PaywallReason)
        case checkIn
        /// 全画面広告（出すかどうかは AdManager が回数のルールで決める）
        case interstitialAd
    }

    private(set) var pendingPresentation: PendingPresentation?

    func showPaywall(_ reason: PaywallReason) {
        paywall = reason
    }

    /// いま閉じている全画面表示・シートが閉じ終わってから、ペイウォールを出す
    func showPaywallAfterDismissal(_ reason: PaywallReason) {
        pendingPresentation = .paywall(reason)
    }

    /// いま閉じている全画面表示・シートが閉じ終わってから、全画面広告を出す（区切りのよいところで出すため）。
    /// ほかに待っている画面（ペイウォールなど）があれば、そちらを優先する。
    func requestInterstitialAfterDismissal() {
        guard pendingPresentation == nil else { return }
        pendingPresentation = .interstitialAd
    }

    /// シート・全画面表示が閉じ終わったときに呼ぶ。待っている画面があれば出す。
    /// - Returns: 全画面広告を出すところなら `.interstitialAd`（広告の表示は呼び出し側で行う）
    @discardableResult
    func didDismissPresentation() -> PendingPresentation? {
        guard let pending = pendingPresentation else { return nil }
        pendingPresentation = nil
        switch pending {
        case .paywall(let reason):
            paywall = reason
        case .checkIn:
            isCheckInPresented = true
        case .interstitialAd:
            break
        }
        return pending
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
        switch kind {
        case .checkIn:
            selectedTab = .home
            // すでにチェックインを開いている
            guard !isCheckInPresented else { return }
            if subscriptionForm != nil || paywall != nil {
                // シートを閉じ終わってからチェックインを出す
                pendingPresentation = .checkIn
                subscriptionForm = nil
                paywall = nil
            } else {
                isCheckInPresented = true
            }
        case .payment, .trial:
            // 開いている画面をすべて閉じて、一覧を見せる
            pendingPresentation = nil
            subscriptionForm = nil
            paywall = nil
            isCheckInPresented = false
            selectedTab = .list
        }
    }
}
