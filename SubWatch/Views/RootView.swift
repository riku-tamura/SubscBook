import SwiftData
import SwiftUI

/// アプリのルート
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MainTabView()
            .onChange(of: scenePhase, initial: true) { _, phase in
                // 起動時・フォアグラウンド復帰時に、過ぎた支払日を次の周期へ進める（5.2）
                if phase == .active {
                    _ = try? PaymentDateCalculator.refreshPaymentDates(in: modelContext)
                }
            }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Subscription.self, CheckIn.self], inMemory: true)
        .environment(AppRouter())
        .environment(EntitlementManager())
}
