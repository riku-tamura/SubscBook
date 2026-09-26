import Foundation
import SwiftData
import Testing
@testable import SubscBook

@Suite("設定の状態")
struct SettingsViewModelTests {
    @Test("データの全削除でサブスク・チェックイン・AI のコメントを消す")
    func deleteAllData() async throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        subscription.recordCheckIn(for: YearMonth("2026-08")!, used: true)
        store.addSubscription(status: .canceled, canceledAt: date(2026, 8, 1))
        try store.context.save()

        let cache = InsightCache(defaults: UserDefaults(suiteName: "SettingsViewModelTests.\(UUID().uuidString)")!)
        cache.setMonthlyComment("コメント", for: "2026-09|key", month: YearMonth("2026-09")!)
        let insights = InsightProvider(service: TemplateInsightService(), cache: cache, availability: .unavailable)
        let entitlements = EntitlementManager(observesTransactions: false)
        let notifications = NotificationScheduler(modelContainer: store.container, entitlements: entitlements)

        let viewModel = SettingsViewModel()
        viewModel.deleteAllData(in: store.context, insights: insights, notifications: notifications)

        #expect(try store.context.fetchCount(FetchDescriptor<Subscription>()) == 0)
        #expect(try store.context.fetchCount(FetchDescriptor<CheckIn>()) == 0)
        #expect(cache.monthlyComment(for: "2026-09|key") == nil)
        #expect(viewModel.deletionMessage == "すべてのデータを削除しました。")
    }

    @Test("未加入のときのプラン名とバージョンの表記")
    func planNameAndVersion() {
        let viewModel = SettingsViewModel()
        #expect(viewModel.planName(of: EntitlementManager(observesTransactions: false)) == "サブスク帳プラス")
        #expect(viewModel.appVersion.contains("（"))
    }
}
