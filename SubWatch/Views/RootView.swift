import SwiftData
import SwiftUI

/// アプリのルート
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(NotificationScheduler.self) private var notifications

    var body: some View {
        MainTabView()
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active {
                    // 起動時・フォアグラウンド復帰時に、過ぎた支払日を次の周期へ進めて通知を登録し直す（5.2・9章）
                    _ = try? PaymentDateCalculator.refreshPaymentDates(in: modelContext)
                    notifications.reschedule()
                }
            }
            .onChange(of: entitlements.isPremium) {
                // トライアル終了の通知はプラスのみ
                notifications.reschedule()
            }
    }
}
