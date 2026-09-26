import Foundation
import SwiftData

@Model
final class Subscription {
    var id: UUID
    /// サービス名
    var name: String
    /// `category` の保存用。#Predicate で enum を扱えないため rawValue で保持する。
    var categoryRawValue: String
    /// 1回あたりの支払額（円）
    var price: Int
    /// `cycle` の保存用
    var cycleRawValue: String
    /// 次回支払日（その日の 0:00 に正規化）
    var nextPaymentDate: Date
    /// 支払日の基準日（1〜31）。1/31 → 2/28 → 3/31 のように、月末で日付が縮んでも元の日に戻すために保持する。
    var billingDay: Int
    /// 無料トライアル終了日（その日の 0:00 に正規化）
    var trialEndDate: Date?
    /// `status` の保存用
    var statusRawValue: String
    /// 解約日
    var canceledAt: Date?
    /// 登録日
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CheckIn.subscription)
    var checkIns: [CheckIn] = []

    init(
        id: UUID = UUID(),
        name: String,
        category: SubscriptionCategory,
        price: Int,
        cycle: BillingCycle,
        nextPaymentDate: Date,
        trialEndDate: Date? = nil,
        status: SubscriptionStatus = .active,
        canceledAt: Date? = nil,
        createdAt: Date = .now,
        calendar: Calendar = .current
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = category.rawValue
        self.price = price
        self.cycleRawValue = cycle.rawValue
        self.nextPaymentDate = calendar.startOfDay(for: nextPaymentDate)
        self.billingDay = calendar.component(.day, from: nextPaymentDate)
        self.trialEndDate = trialEndDate.map { calendar.startOfDay(for: $0) }
        self.statusRawValue = status.rawValue
        self.canceledAt = canceledAt
        self.createdAt = createdAt
    }
}

// MARK: - enum アクセサ

extension Subscription {
    var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var cycle: BillingCycle {
        get { BillingCycle(rawValue: cycleRawValue) ?? .monthly }
        set { cycleRawValue = newValue.rawValue }
    }

    var status: SubscriptionStatus {
        get { SubscriptionStatus(rawValue: statusRawValue) ?? .active }
        set { statusRawValue = newValue.rawValue }
    }

    var isActive: Bool {
        status == .active
    }

    /// 有効なサブスクを取得する述語（@Query / FetchDescriptor 用）
    static var activePredicate: Predicate<Subscription> {
        let active = SubscriptionStatus.active.rawValue
        return #Predicate { $0.statusRawValue == active }
    }
}

// MARK: - 金額

extension Subscription {
    /// 月額換算（5.1）
    var monthlyEquivalent: Int {
        CostCalculator.monthlyEquivalent(price: price, cycle: cycle)
    }

    /// 1年あたりの支払額。年額プランは実際の金額（月額換算 × 12 だと丸め誤差が出るため）
    var annualCost: Int {
        CostCalculator.annualCost(price: price, cycle: cycle)
    }
}

// MARK: - 状態の変更

extension Subscription {
    /// 次回支払日をユーザーが指定した日に変更する。基準日（billingDay）も合わせて更新する。
    func setNextPaymentDate(_ date: Date, calendar: Calendar = .current) {
        nextPaymentDate = calendar.startOfDay(for: date)
        billingDay = calendar.component(.day, from: date)
    }

    func setTrialEndDate(_ date: Date?, calendar: Calendar = .current) {
        trialEndDate = date.map { calendar.startOfDay(for: $0) }
    }

    /// 解約済みにする
    func cancel(at date: Date = .now) {
        status = .canceled
        canceledAt = date
    }
}

// MARK: - チェックイン

extension Subscription {
    /// 指定月のチェックイン。同じ月に複数ある場合は最後に回答したものを返す。
    func checkIn(for month: YearMonth) -> CheckIn? {
        checkIns
            .filter { $0.month == month.key }
            .max { $0.answeredAt < $1.answeredAt }
    }

    /// 指定月のチェックインを記録する。すでに回答済みの場合は上書きする。
    @discardableResult
    func recordCheckIn(for month: YearMonth, used: Bool, at date: Date = .now) -> CheckIn {
        if let existing = checkIn(for: month) {
            existing.used = used
            existing.answeredAt = date
            return existing
        }
        let checkIn = CheckIn(month: month, used: used, answeredAt: date)
        checkIns.append(checkIn)
        return checkIn
    }
}
