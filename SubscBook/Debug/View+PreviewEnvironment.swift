#if DEBUG
import SwiftData
import SwiftUI

extension View {
    /// プレビュー用に、アプリと同じ環境（インメモリのデータ）を用意する
    func previewEnvironment(seeded: Bool = false) -> some View {
        let container = try! ModelContainer(
            for: Subscription.self, CheckIn.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        if seeded {
            try? SampleData.seed(into: container.mainContext)
        }
        let entitlements = EntitlementManager(observesTransactions: false)
        return modelContainer(container)
            .environment(AppRouter())
            .environment(entitlements)
            .environment(NotificationScheduler(modelContainer: container, entitlements: entitlements))
            .environment(InsightProvider(service: TemplateInsightService(), cache: InsightCache(), availability: .unavailable))
            .environment(\.locale, .japanese)
    }
}
#endif
