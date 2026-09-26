import Foundation
import SwiftData
@testable import SubWatch

extension Calendar {
    /// テストはタイムゾーンを固定して実行する
    nonisolated static let tokyo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }()
}

/// 東京時間で日時を作る
nonisolated func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    Calendar.tokyo.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// テストごとに作るインメモリの SwiftData ストア
struct TestStore {
    let container: ModelContainer

    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: Subscription.self, CheckIn.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @discardableResult
    func addSubscription(
        name: String = "テストサービス",
        category: SubscriptionCategory = .video,
        price: Int = 1000,
        cycle: BillingCycle = .monthly,
        nextPaymentDate: Date = date(2026, 10, 15),
        status: SubscriptionStatus = .active,
        canceledAt: Date? = nil,
        createdAt: Date = date(2026, 1, 1)
    ) -> Subscription {
        let subscription = Subscription(
            name: name,
            category: category,
            price: price,
            cycle: cycle,
            nextPaymentDate: nextPaymentDate,
            status: status,
            canceledAt: canceledAt,
            createdAt: createdAt,
            calendar: .tokyo
        )
        context.insert(subscription)
        return subscription
    }
}
