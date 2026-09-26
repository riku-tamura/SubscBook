import SwiftData
import SwiftUI

/// タブ構成（ホーム / 一覧 / レポート / 設定）と、アプリ全体で使うシート
struct MainTabView: View {
    @Environment(AppRouter.self) private var router

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
        .sheet(item: $router.subscriptionForm) { route in
            NavigationStack {
                switch route {
                case .add:
                    SubscriptionFormView(mode: .add)
                case .edit(let subscription):
                    SubscriptionFormView(mode: .edit(subscription))
                }
            }
        }
        .sheet(item: $router.paywall) { reason in
            PaywallView(reason: reason)
        }
    }
}
