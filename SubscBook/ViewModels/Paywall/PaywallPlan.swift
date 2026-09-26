import Foundation
import StoreKit

/// ペイウォールに表示するプラン（⑦）。価格は App Store の表示価格を使う。
struct PaywallPlan: Identifiable, Equatable {
    let id: String
    let isYearly: Bool
    /// "¥2,400"
    let displayPrice: String
    /// "月あたり¥200"（年額のみ）
    let perMonthText: String?
    /// "1週間無料"（導入オファーの利用資格がある場合のみ）
    let trialText: String?

    var title: String { isYearly ? "年額プラン" : "月額プラン" }
    var periodUnit: String { isYearly ? "年" : "月" }
    /// "¥2,400/年"
    var priceText: String { "\(displayPrice)/\(periodUnit)" }

    init(id: String, isYearly: Bool, displayPrice: String, perMonthText: String?, trialText: String?) {
        self.id = id
        self.isYearly = isYearly
        self.displayPrice = displayPrice
        self.perMonthText = perMonthText
        self.trialText = trialText
    }

    init(product: Product, isEligibleForIntroOffer: Bool) {
        let isYearly = product.subscription?.subscriptionPeriod.unit == .year
        var perMonthText: String?
        if isYearly {
            var perMonth = product.price / 12
            var rounded = Decimal()
            NSDecimalRound(&rounded, &perMonth, 0, .down)
            perMonthText = "月あたり\(rounded.formatted(product.priceFormatStyle))"
        }
        var trialText: String?
        if isEligibleForIntroOffer,
           let offer = product.subscription?.introductoryOffer,
           offer.paymentMode == .freeTrial {
            trialText = "\(Self.periodText(value: offer.period.value, unit: offer.period.unit))無料"
        }
        self.init(
            id: product.id,
            isYearly: isYearly,
            displayPrice: product.displayPrice,
            perMonthText: perMonthText,
            trialText: trialText
        )
    }

    /// "1週間" / "3日間" / "1ヶ月" / "1年"
    nonisolated static func periodText(value: Int, unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: "\(value)日間"
        case .week: "\(value)週間"
        case .month: "\(value)ヶ月"
        case .year: "\(value)年"
        @unknown default: "\(value)"
        }
    }

    #if DEBUG
    /// StoreKit の商品が読めない環境で画面を確認するためのサンプル
    static let samples = [
        PaywallPlan(id: PremiumProducts.yearly, isYearly: true, displayPrice: "¥2,400", perMonthText: "月あたり¥200", trialText: "1週間無料"),
        PaywallPlan(id: PremiumProducts.monthly, isYearly: false, displayPrice: "¥300", perMonthText: nil, trialText: nil),
    ]
    #endif
}
