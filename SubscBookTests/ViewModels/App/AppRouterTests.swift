import Foundation
import Testing
@testable import SubscBook

@Suite("画面遷移")
struct AppRouterTests {
    @Test("上限に達しているとペイウォール、そうでなければ登録画面を開く")
    func requestNewSubscription() {
        let router = AppRouter()
        router.requestNewSubscription(activeCount: 4, isPremium: false)
        #expect(router.subscriptionForm?.id == "add")
        #expect(router.paywall == nil)

        router.subscriptionForm = nil
        router.requestNewSubscription(activeCount: 5, isPremium: false)
        #expect(router.subscriptionForm == nil)
        #expect(router.paywall == .subscriptionLimit)
    }

    @Test("通知をタップしたときの遷移")
    func openNotification() {
        let router = AppRouter()
        router.openNotification(.checkIn)
        #expect(router.selectedTab == .home)
        #expect(router.isCheckInPresented)

        // シート表示中は、閉じ終わってからチェックインを出す
        let presenting = AppRouter()
        presenting.paywall = .settings
        presenting.openNotification(.checkIn)
        #expect(presenting.paywall == nil)
        #expect(!presenting.isCheckInPresented)
        #expect(presenting.pendingPresentation == .checkIn)
        presenting.didDismissPresentation()
        #expect(presenting.isCheckInPresented)
        #expect(presenting.pendingPresentation == nil)

        let other = AppRouter()
        other.openNotification(.payment)
        #expect(other.selectedTab == .list)
        #expect(!other.isCheckInPresented)
    }

    @Test("チェックインを開いているときに支払いの通知をタップすると、閉じて一覧を見せる")
    func paymentNotificationClosesCheckIn() {
        let router = AppRouter()
        router.isCheckInPresented = true
        router.openNotification(.trial)
        #expect(!router.isCheckInPresented)
        #expect(router.selectedTab == .list)
    }

    @Test("閉じ終わってからペイウォールを出す")
    func paywallAfterDismissal() {
        let router = AppRouter()
        router.isCheckInPresented = true
        router.isCheckInPresented = false
        router.showPaywallAfterDismissal(.lockedFeature(.cancelSuggestions))
        #expect(router.paywall == nil)
        router.didDismissPresentation()
        #expect(router.paywall == .lockedFeature(.cancelSuggestions))
        // 待っているものがなければ何もしない
        router.paywall = nil
        router.didDismissPresentation()
        #expect(router.paywall == nil)
    }

    @Test("全画面広告は閉じ終わってから。ほかに待っている画面があればそちらを優先する")
    func interstitialAfterDismissal() {
        let router = AppRouter()
        router.requestInterstitialAfterDismissal()
        #expect(router.didDismissPresentation() == .interstitialAd)
        #expect(router.pendingPresentation == nil)

        // ペイウォールを待っているときは、広告の依頼で上書きしない
        router.showPaywallAfterDismissal(.lockedFeature(.cancelSuggestions))
        router.requestInterstitialAfterDismissal()
        #expect(router.didDismissPresentation() == .paywall(.lockedFeature(.cancelSuggestions)))
        #expect(router.paywall == .lockedFeature(.cancelSuggestions))
    }
}
