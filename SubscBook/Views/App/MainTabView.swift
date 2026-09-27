import SwiftUI

/// タブ構成（ホーム / 一覧 / レポート / 設定）と、アプリ全体で使うシート
struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AdManager.self) private var ads
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            Tab("ホーム", systemImage: "house", value: AppRouter.Tab.home) {
                HomeView()
            }
            Tab("一覧", systemImage: "list.bullet", value: AppRouter.Tab.list) {
                SubscriptionListView()
            }
            Tab("レポート", systemImage: "chart.pie", value: AppRouter.Tab.report) {
                ReportView()
            }
            Tab("設定", systemImage: "gearshape", value: AppRouter.Tab.settings) {
                SettingsView()
            }
        }
        .sheet(item: $router.subscriptionForm, onDismiss: handleDismissal) { route in
            NavigationStack {
                switch route {
                case .add:
                    SubscriptionFormView(mode: .add)
                case .edit(let subscription):
                    SubscriptionFormView(mode: .edit(subscription))
                }
            }
        }
        .sheet(item: $router.paywall, onDismiss: handleDismissal) { reason in
            PaywallView(reason: reason)
        }
        .fullScreenCover(isPresented: $router.isCheckInPresented, onDismiss: handleDismissal) {
            CheckInView()
        }
    }

    /// シート・全画面表示が閉じ終わったら、待っている画面か全画面広告を出す
    private func handleDismissal() {
        if router.didDismissPresentation() == .interstitialAd {
            ads.showInterstitialIfAllowed(isPremium: entitlements.isPremium)
        }
    }
}
