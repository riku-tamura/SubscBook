import Foundation
import SwiftData
import Testing
@testable import SubscBook

@Suite("設定の状態")
struct SettingsViewModelTests {
    @Test("データの全削除でサブスク・チェックイン・AI のコメントを消す")
    func deleteAllData() throws {
        let store = try TestStore()
        let subscription = store.addSubscription()
        subscription.recordCheckIn(for: YearMonth("2026-08")!, used: true)
        store.addSubscription(status: .canceled, canceledAt: date(2026, 8, 1))
        try store.context.save()

        let cache = InsightCache(defaults: UserDefaults(suiteName: "SettingsViewModelTests.\(UUID().uuidString)")!)
        cache.setMonthlyComment("コメント", for: "2026-09|key", month: YearMonth("2026-09")!)
        let insights = InsightProvider(service: TemplateInsightService(), cache: cache, availability: .unavailable)

        let viewModel = SettingsViewModel()
        viewModel.deleteAllData(in: store.context, insights: insights)

        #expect(try store.context.fetchCount(FetchDescriptor<Subscription>()) == 0)
        #expect(try store.context.fetchCount(FetchDescriptor<CheckIn>()) == 0)
        #expect(cache.monthlyComment(for: "2026-09|key") == nil)
        #expect(viewModel.deletionMessage == "すべてのデータを削除しました。")
    }

    @Test("無料期間中は、課金が始まる日だとわかる表記にする", arguments: [
        (true, true, "無料期間の終了日", true),
        (true, false, "無料期間の終了日", true),
        (false, true, "次回の更新日", false),
        (false, false, "有効期限", true),
    ])
    func expirationWording(isInFreeTrial: Bool, willAutoRenew: Bool, label: String, hasNote: Bool) {
        let plan = EntitlementManager.ActivePlan(
            productID: PremiumProducts.yearly, expirationDate: date(2026, 10, 3),
            willAutoRenew: willAutoRenew, isInFreeTrial: isInFreeTrial
        )
        let viewModel = SettingsViewModel()
        #expect(viewModel.expirationLabel(for: plan) == label)
        #expect((viewModel.renewalNote(for: plan) != nil) == hasNote)
    }

    @Test("未加入のときのプラン名とバージョンの表記")
    func planNameAndVersion() {
        let viewModel = SettingsViewModel()
        #expect(viewModel.planName(of: EntitlementManager(observesTransactions: false)) == "サブスク帳プラス")
        #expect(viewModel.appVersion.contains("（"))
    }
}
