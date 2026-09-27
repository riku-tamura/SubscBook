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
        guard !isPremium, !isStarting else { return }
        guard !isReady else {
            // 準備済みなら、前に読み込めなかった全画面広告を読み込み直す（起動時に圏外だった場合など）
            await loadInterstitialIfNeeded()
            return
        }
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
        guard !isPremium, isReady else { return }
        guard let interstitial else {
            // 読み込めていなければ、次の機会のために読み込み直す
            Task { await loadInterstitialIfNeeded() }
            return
        }
        let firstLaunch = defaults.object(forKey: Self.firstLaunchDateKey) as? Date ?? now
        var canShow = InterstitialAdPolicy.canShow(now: now, firstLaunchDate: firstLaunch, shownDates: shownDates)
        #if DEBUG
        canShow = canShow || DebugLaunchOptions.ignoresAdLimits
        #endif
        guard canShow else { return }

        // 読み込んでから時間がたって表示できない広告は捨てて、読み込み直す
        do {
            try interstitial.canPresent(from: nil)
        } catch {
            self.interstitial = nil
            Task { await loadInterstitialIfNeeded() }
            return
        }
        // 出した日時は、実際に表示されたとき（adWillPresentFullScreenContent）に記録する
        interstitial.present(from: nil)
        self.interstitial = nil
    }

    private var shownDates: [Date] {
        defaults.array(forKey: Self.interstitialDatesKey) as? [Date] ?? []
    }

    /// 全画面広告を出した日時を記録する（回数のルールに使う）
    private func recordInterstitialShown(at date: Date = .now) {
        defaults.set(InterstitialAdPolicy.datesToKeep(shownDates + [date], now: date), forKey: Self.interstitialDatesKey)
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
            // 読み込めなくても、次に出すきっかけや前面に戻ったときに読み込み直す
            Self.logger.notice("Interstitial load failed: \(String(describing: type(of: error)), privacy: .public)")
        }
    }
}

extension AdManager: FullScreenContentDelegate {
    /// 実際に表示されたときだけ、出した日時を記録する（表示に失敗したら回数に数えない）
    func adWillPresentFullScreenContent(_ ad: any FullScreenPresentingAd) {
        recordInterstitialShown()
    }

    /// 閉じたら次の全画面広告を読み込んでおく
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        Task { await loadInterstitialIfNeeded() }
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        Task { await loadInterstitialIfNeeded() }
    }
}
