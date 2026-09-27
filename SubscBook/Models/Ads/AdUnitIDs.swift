import Foundation

/// AdMob の広告ユニット ID。Build Settings（`ADMOB_*`）から Info.plist 経由で読む。
/// 開発中は Google のテスト用 ID を使う。公開前に AdMob で作った ID に差し替える（docs/ads.md）。
nonisolated enum AdUnitIDs {
    /// Google が公開しているテスト用のアプリ ID（本番の ID に差し替えたかの確認に使う）
    static let testApplicationID = "ca-app-pub-3940256099942544~1458002511"

    static var banner: String? { value(forKey: "SubscBookAdMobBannerUnitID") }
    static var interstitial: String? { value(forKey: "SubscBookAdMobInterstitialUnitID") }
    static var application: String? { value(forKey: "GADApplicationIdentifier") }

    /// テスト用の ID のままか
    static var usesTestIDs: Bool { application == testApplicationID }

    private static func value(forKey key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else { return nil }
        return value
    }
}
