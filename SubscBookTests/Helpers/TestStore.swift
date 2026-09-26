import Foundation
import SwiftData
@testable import SubscBook

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
