#if DEBUG
import Foundation
import SwiftData
import SwiftUI

/// 開発用の起動オプション（Scheme の Arguments や simctl launch で指定する）
enum DebugLaunchOptions {
    private static let arguments = ProcessInfo.processInfo.arguments

    /// 既存データを消してサンプルデータを入れる
    static let seedsSampleData = arguments.contains("-seedSampleData")
    /// 購入せずにサブスク帳プラスを有効にする
    static let forcesPremium = arguments.contains("-forcePremium")
    /// StoreKit の商品が読めない環境で、ペイウォールにサンプルのプランを表示する
    static let usesSamplePlans = arguments.contains("-samplePlans")
    /// オンボーディングを表示しない
    static let skipsOnboarding = arguments.contains("-skipOnboarding")
}

extension View {
    /// プレビュー用に、アプリと同じ環境（インメモリのデータ）を用意する
    func previewEnvironment(seeded: Bool = false) -> some View {
        let container = try! ModelContainer(
            for: Subscription.self, CheckIn.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        if seeded {
            try? SampleData.seed(into: container.mainContext)
        }
        let entitlements = EntitlementManager(observesTransactions: false)
        return modelContainer(container)
            .environment(AppRouter())
            .environment(entitlements)
            .environment(NotificationScheduler(modelContainer: container, entitlements: entitlements))
            .environment(InsightProvider(service: TemplateInsightService(), cache: InsightCache(), availability: .unavailable))
            .environment(\.locale, .japanese)
    }
}

/// 画面確認用のサンプルデータ
enum SampleData {
    static func seed(into context: ModelContext, now: Date = .now, calendar: Calendar = .current) throws {
        for subscription in try context.fetch(FetchDescriptor<Subscription>()) {
            context.delete(subscription)
        }

        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
        }
        let registered = calendar.date(byAdding: .month, value: -6, to: now)!
        let lastMonth = MonthlyCheckInPolicy.targetMonth(now: now, calendar: calendar)
        let twoMonthsAgo = lastMonth.previous

        func add(
            _ name: String, _ category: SubscriptionCategory, _ price: Int, _ cycle: BillingCycle = .monthly,
            next: Int, trialEnd: Int? = nil, canceledDaysAgo: Int? = nil,
            checkIns: [(YearMonth, Bool)] = []
        ) {
            let subscription = Subscription(
                name: name, category: category, price: price, cycle: cycle,
                nextPaymentDate: day(next),
                trialEndDate: trialEnd.map(day),
                status: canceledDaysAgo == nil ? .active : .canceled,
                canceledAt: canceledDaysAgo.map { day(-$0) },
                createdAt: registered,
                calendar: calendar
            )
            context.insert(subscription)
            for (month, used) in checkIns {
                subscription.recordCheckIn(for: month, used: used, at: now)
            }
        }

        add("Netflix", .video, 1590, next: 3, checkIns: [(twoMonthsAgo, true)])
        add("U-NEXT", .video, 2189, next: 12, checkIns: [(twoMonthsAgo, false), (lastMonth, false)])
        add("Disney+", .video, 1140, next: 20, checkIns: [(twoMonthsAgo, false)])
        add("Spotify", .music, 1080, next: 1, checkIns: [(twoMonthsAgo, true), (lastMonth, true)])
        add("iCloud+", .cloud, 450, next: 8, checkIns: [(twoMonthsAgo, true), (lastMonth, true)])
        add("Duolingo Super", .learning, 12800, .yearly, next: 5, trialEnd: 5)
        add("Kindle Unlimited", .reading, 980, next: -40, canceledDaysAgo: 95)
        add("Hulu", .video, 1026, next: -10, canceledDaysAgo: 40)

        try context.save()
    }
}
#endif
