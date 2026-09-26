import Foundation

extension Subscription {
    /// "1,490円/月"
    var priceText: String {
        "\(price.yenText)/\(cycle.unitLabel)"
    }

    /// VoiceOver 用の金額表現（"1,490円、毎月"）
    var priceAccessibilityText: String {
        "\(price.yenText)、\(cycle.displayName)"
    }
}
