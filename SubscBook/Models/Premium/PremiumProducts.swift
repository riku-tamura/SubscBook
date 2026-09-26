import Foundation
import StoreKit

/// サブスク帳プラスの商品（7章）
nonisolated enum PremiumProducts {
    /// Product ID の接頭辞。Bundle ID を変えた場合はここと Products.storekit を合わせて変更する。
    static let prefix = "com.hachimaki.SubscBook"
    static let monthly = "\(prefix).premium.monthly"
    static let yearly = "\(prefix).premium.yearly"
    /// 表示順（年額を上に）
    static let all = [yearly, monthly]
}
