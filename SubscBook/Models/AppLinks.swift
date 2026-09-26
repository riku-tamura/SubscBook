import Foundation

/// アプリ内から開く外部リンク
nonisolated enum AppLinks {
    /// 利用規約（Apple 標準の使用許諾契約）。独自の規約を用意した場合は差し替える。
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
