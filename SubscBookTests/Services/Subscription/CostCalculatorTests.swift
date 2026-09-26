import Testing
@testable import SubscBook

@Suite("金額計算（5.1）")
struct CostCalculatorTests {
    @Test("月額プランは金額がそのまま月額換算になる", arguments: [0, 1, 980, 1490])
    func monthlyEquivalentOfMonthlyPlan(price: Int) {
        #expect(CostCalculator.monthlyEquivalent(price: price, cycle: .monthly) == price)
    }

    @Test("年額プランは12で割って四捨五入する", arguments: [
        (12000, 1000),
        (10000, 833),  // 833.33
        (5900, 492),   // 491.67
        (1002, 84),    // 83.5 → 切り上げ
        (18, 2),       // 1.5 → 切り上げ
        (6, 1),        // 0.5 → 切り上げ
        (5, 0),        // 0.42
        (0, 0),
    ])
    func monthlyEquivalentOfYearlyPlan(price: Int, expected: Int) {
        #expect(CostCalculator.monthlyEquivalent(price: price, cycle: .yearly) == expected)
    }

    @Test("負の金額は0として扱う")
    func negativePrice() {
        #expect(CostCalculator.monthlyEquivalent(price: -100, cycle: .monthly) == 0)
        #expect(CostCalculator.monthlyEquivalent(price: -1200, cycle: .yearly) == 0)
    }

    @Test("月額合計・年額合計は有効なサブスクのみを合計する")
    func totalsIncludeOnlyActive() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(price: 980, cycle: .monthly),
            store.addSubscription(price: 10000, cycle: .yearly),
            store.addSubscription(price: 1490, cycle: .monthly, status: .canceled, canceledAt: date(2026, 8, 1)),
        ]

        #expect(CostCalculator.monthlyTotal(of: subscriptions) == 980 + 833)
        // 年額プランは実際の金額で合計する
        #expect(CostCalculator.annualTotal(of: subscriptions) == 980 * 12 + 10000)
    }

    @Test("サブスクがなければ合計は0")
    func emptyTotals() {
        #expect(CostCalculator.monthlyTotal(of: []) == 0)
        #expect(CostCalculator.annualTotal(of: []) == 0)
    }

    @Test("1年あたりの支払額は、月額は × 12、年額はそのまま")
    func annualCost() throws {
        let store = try TestStore()
        let monthly = store.addSubscription(price: 980, cycle: .monthly)
        let yearly = store.addSubscription(price: 10000, cycle: .yearly)

        #expect(monthly.annualCost == 11760)
        #expect(yearly.monthlyEquivalent == 833)
        #expect(yearly.annualCost == 10000)
    }
}
