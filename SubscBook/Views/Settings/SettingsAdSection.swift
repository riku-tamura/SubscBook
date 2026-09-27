import SwiftUI
import UIKit

/// 広告について（無料プランのみ）。広告を消す方法と、トラッキングの許可の変え方を案内する。
struct SettingsAdSection: View {
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL

    var body: some View {
        if !entitlements.isPremium {
            Section {
                Button("広告を非表示にする", systemImage: "rectangle.slash") {
                    router.showPaywall(.lockedFeature(.adFree))
                }
                Button("トラッキングの許可を変更", systemImage: "hand.raised") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            } header: {
                Text("広告")
            } footer: {
                Text("無料プランでは広告を表示します。登録したサブスクの情報は広告に使いません。サブスク帳プラスでは広告を表示しません。")
            }
        }
    }
}
