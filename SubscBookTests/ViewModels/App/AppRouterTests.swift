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
    func openNotification() async throws {
        let router = AppRouter()
        router.openNotification(.checkIn)
        #expect(router.selectedTab == .home)
        #expect(router.isCheckInPresented)

        // シート表示中は閉じてからチェックインを出す
        let presenting = AppRouter()
        presenting.paywall = .settings
        presenting.openNotification(.checkIn)
        #expect(presenting.paywall == nil)
        #expect(!presenting.isCheckInPresented)
        try await Task.sleep(for: AppRouter.sheetDismissDelay + .milliseconds(200))
        #expect(presenting.isCheckInPresented)

        let other = AppRouter()
        other.openNotification(.payment)
        #expect(other.selectedTab == .list)
        #expect(!other.isCheckInPresented)
    }
}
