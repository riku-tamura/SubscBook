import Foundation

/// ペイウォールで表示するメッセージ
struct PaywallMessage: Identifiable, Equatable {
    let title: String
    let body: String
    /// OK を押したらペイウォールを閉じる
    var dismissesPaywall = false

    var id: String { title + body }
}
