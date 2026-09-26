import Foundation
import Testing
@testable import SubscBook

@Suite("無料プランの制限")
struct FreePlanTests {
    @Test("無料は有効なサブスク5件まで、プラスは無制限", arguments: [
        (0, false, true),
        (4, false, true),
        (5, false, false),
        (5, true, true),
        (100, true, true),
    ])
    func canAdd(activeCount: Int, isPremium: Bool, expected: Bool) {
        #expect(FreePlan.canAddSubscription(activeCount: activeCount, isPremium: isPremium) == expected)
    }
}
