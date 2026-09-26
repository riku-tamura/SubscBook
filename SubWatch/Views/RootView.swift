import SwiftData
import SwiftUI

/// アプリのルート。Phase 2 で TabView に置き換える。
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ContentUnavailableView(
            "サブスク見張り番",
            systemImage: "eye",
            description: Text("準備中です")
        )
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
}
