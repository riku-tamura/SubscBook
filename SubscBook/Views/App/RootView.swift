import SwiftData
import SwiftUI

/// アプリのルート
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(NotificationScheduler.self) private var notifications
    @Environment(InsightProvider.self) private var insights
    @Environment(AdManager.self) private var ads
    @AppStorage(OnboardingViewModel.completedKey) private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear(perform: skipOnboardingIfNeeded)
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                // 起動時・フォアグラウンド復帰時に、過ぎた支払日を次の周期へ進めて通知を登録し直す（5.2・9章）
                _ = try? PaymentDateCalculator.refreshPaymentDates(in: modelContext)
                notifications.reschedule()
                // AI モデルの準備完了や Apple Intelligence の設定変更を反映する（8.1）
                insights.refreshAvailability()
                // 期限切れ・返金は Transaction.updates に流れないことがあるので、復帰時にも確かめる。
                // 広告は購読状態がわかってから準備する（プラスの人にトラッキングの許可を求めないため）
                Task {
                    await entitlements.refreshEntitlements()
                    await prepareAdsIfNeeded()
                }
            }
        }
        .onChange(of: entitlements.isPremium) {
            // トライアル終了の通知はプラスのみ
            notifications.reschedule()
            // プラスの期限が切れたら広告を出せるようにする
            Task { await prepareAdsIfNeeded() }
        }
        .onChange(of: entitlements.hasLoadedEntitlements) {
            // 起動直後に読み込みが重なって後回しになった場合も、読み終えたら準備する
            Task { await prepareAdsIfNeeded() }
        }
        .onChange(of: hasCompletedOnboarding) {
            // オンボーディングを終えた直後（通知の許可のダイアログと重ならないよう、終わってから）
            Task { await prepareAdsIfNeeded() }
        }
    }

    /// オンボーディングを終えていて、アプリが前面にあり、購読状態を読み終えているときだけ広告を準備する。
    /// （トラッキングの許可を求めるため。プラスかどうかわからないうちに、プラスの人に許可を求めないため）
    private func prepareAdsIfNeeded() async {
        guard hasCompletedOnboarding, scenePhase == .active, entitlements.hasLoadedEntitlements else { return }
        #if DEBUG
        if DebugLaunchOptions.isRunningTests { return }
        #endif
        await ads.prepareIfNeeded(isPremium: entitlements.isPremium)
    }

    /// すでにデータがある場合（開発時のサンプルデータなど）はオンボーディングを出さない
    private func skipOnboardingIfNeeded() {
        guard !hasCompletedOnboarding else { return }
        #if DEBUG
        if DebugLaunchOptions.skipsOnboarding {
            hasCompletedOnboarding = true
            return
        }
        #endif
        let count = (try? modelContext.fetchCount(FetchDescriptor<Subscription>())) ?? 0
        if count > 0 {
            hasCompletedOnboarding = true
        }
    }
}
