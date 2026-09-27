import GoogleMobileAds
import SwiftUI
import UIKit

/// 画面の下に出すバナー広告（ホーム・一覧・レポート）。サブスク帳プラスの人には出さない。
/// 広告が届くまでは場所を取らない。タブバーやボタンと接していると誤タップを誘う配置として
/// AdMob のポリシー違反になりうるため、上下に余白を取る。
struct AdBanner: View {
    /// 上下の余白（タブバーと画面の内容から離す）
    static let verticalPadding: CGFloat = 10

    @Environment(AdManager.self) private var ads
    @Environment(EntitlementManager.self) private var entitlements
    /// 届いた広告の高さ（届くまでは 0）
    @State private var height: CGFloat = 0

    var body: some View {
        if ads.showsBanner(isPremium: entitlements.isPremium), let unitID = AdUnitIDs.banner {
            GeometryReader { proxy in
                BannerAdView(unitID: unitID, width: proxy.size.width) { height = $0 }
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .padding(.vertical, height > 0 ? Self.verticalPadding : 0)
            .background(.bar)
        }
    }
}

/// AdMob のバナー（幅に合わせた高さのアンカー型アダプティブバナー）。
/// SwiftUI にバナーの大きさを決めさせると広告がずれるため、入れ物の中央に広告の大きさで置く。
private struct BannerAdView: UIViewRepresentable {
    let unitID: String
    let width: CGFloat
    /// 広告が届いたら高さを、届かなかったら 0 を返す
    let onHeightChange: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onHeightChange: onHeightChange)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = unitID
        banner.delegate = context.coordinator
        banner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            banner.topAnchor.constraint(equalTo: container.topAnchor),
        ])
        context.coordinator.banner = banner
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onHeightChange = onHeightChange
        // 幅が決まったとき・変わったときだけ、その幅に合わせて読み込む
        guard width > 0, abs(coordinator.loadedWidth - width) > 1, let banner = coordinator.banner else { return }
        coordinator.loadedWidth = width
        let adSize = largeAnchoredAdaptiveBanner(width: width)
        banner.adSize = adSize
        coordinator.setSize(adSize.size)
        banner.load(Request())
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var onHeightChange: (CGFloat) -> Void
        var loadedWidth: CGFloat = 0
        /// 一度でも広告が届いたか（自動の入れ替えに失敗しても、表示中の広告は残るので隠さない）
        var hasReceivedAd = false
        weak var banner: BannerView?
        private var sizeConstraints: [NSLayoutConstraint] = []

        init(onHeightChange: @escaping (CGFloat) -> Void) {
            self.onHeightChange = onHeightChange
        }

        /// バナーを広告の大きさに固定する
        func setSize(_ size: CGSize) {
            guard let banner else { return }
            NSLayoutConstraint.deactivate(sizeConstraints)
            sizeConstraints = [
                banner.widthAnchor.constraint(equalToConstant: size.width),
                banner.heightAnchor.constraint(equalToConstant: size.height),
            ]
            NSLayoutConstraint.activate(sizeConstraints)
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            hasReceivedAd = true
            onHeightChange(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            // 最初の読み込みに失敗したときだけ隠す（入れ替えの失敗では、前の広告が表示されたまま）
            if !hasReceivedAd {
                onHeightChange(0)
            }
        }
    }
}
