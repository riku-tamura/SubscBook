import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import Observation
import OSLog
import UIKit

/// 広告（Google AdMob）の準備と全画面広告の表示。サブスク帳プラスの人には広告を出さない。
///
/// 流れ：オンボーディングを終えてアプリが前面にあるときに、トラッキングの許可を求め（1回だけ）、
/// その後に SDK を始めてバナーを出せるようにし、全画面広告を読み込んでおく。
@Observable
final class AdManager: NSObject {
    static let firstLaunchDateKey = "ads.firstLaunchDate"
    static let interstitialDatesKey = "ads.interstitialShownDates"

    /// SDK を始めて、広告を読み込めるようになったか（バナーはこれが true のときだけ出す）
    private(set) var isReady = false

    @ObservationIgnored private var isStarting = false
    @ObservationIgnored private var interstitial: InterstitialAd?
    @ObservationIgnored private var isLoadingInterstitial = false
    @ObservationIgnored private let defaults: UserDefaults
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SubscBook", category: "Ads")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        if defaults.object(forKey: Self.firstLaunchDateKey) == nil {
            defaults.set(Date.now, forKey: Self.firstLaunchDateKey)
        }
    }

    /// バナーを出すか
    func showsBanner(isPremium: Bool) -> Bool {
        isReady && !isPremium
    }

    /// 広告の準備をする。オンボーディングの後、アプリが前面にあるときに呼ぶ（トラッキングの許可のダイアログを出すため）。
    /// サブスク帳プラスの人には何もしない。
    func prepareIfNeeded(isPremium: Bool) async {
        guard !isPremium, !isReady, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // 前面になった直後はダイアログが出ないことがあるため、少し待ってから求める
            try? await Task.sleep(for: .milliseconds(500))
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        _ = await MobileAds.shared.start()
        #if !DEBUG
        if AdUnitIDs.usesTestIDs {
            Self.logger.error("AdMob のテスト用 ID のまま公開用にビルドしています")
        }
        #endif
        isReady = true
        await loadInterstitialIfNeeded()
    }

    /// 全画面広告を出す。ルール（`InterstitialAdPolicy`）で出せないとき、読み込めていないときは何もしない。
    /// 画面を閉じ終わってから呼ぶ（`AppRouter.requestInterstitialAfterDismissal`）。
    func showInterstitialIfAllowed(isPremium: Bool, now: Date = .now) {
        guard !isPremium, isReady, let interstitial else { return }
        let firstLaunch = defaults.object(forKey: Self.firstLaunchDateKey) as? Date ?? now
        let shown = defaults.array(forKey: Self.interstitialDatesKey) as? [Date] ?? []
        var canShow = InterstitialAdPolicy.canShow(now: now, firstLaunchDate: firstLaunch, shownDates: shown)
        #if DEBUG
        canShow = canShow || DebugLaunchOptions.ignoresAdLimits
        #endif
        guard canShow else { return }

        interstitial.present(from: nil)
        self.interstitial = nil
        defaults.set(InterstitialAdPolicy.datesToKeep(shown + [now], now: now), forKey: Self.interstitialDatesKey)
    }

    private func loadInterstitialIfNeeded() async {
        guard interstitial == nil, !isLoadingInterstitial, let unitID = AdUnitIDs.interstitial else { return }
        isLoadingInterstitial = true
        defer { isLoadingInterstitial = false }
        do {
            let ad = try await InterstitialAd.load(with: unitID, request: Request())
            ad.fullScreenContentDelegate = self
            interstitial = ad
        } catch {
            // 読み込めなくても、次に閉じたときに読み込み直す
            Self.logger.notice("Interstitial load failed: \(String(describing: type(of: error)), privacy: .public)")
        }
    }
}

extension AdManager: FullScreenContentDelegate {
    /// 閉じたら次の全画面広告を読み込んでおく
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        Task { await loadInterstitialIfNeeded() }
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        Task { await loadInterstitialIfNeeded() }
    }
}
