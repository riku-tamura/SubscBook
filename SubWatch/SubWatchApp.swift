import SwiftData
import SwiftUI

@main
struct SubWatchApp: App {
    @State private var router = AppRouter()
    @State private var entitlements = EntitlementManager()
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Subscription.self, CheckIn.self)
        } catch {
            fatalError("データベースを開けませんでした: \(error)")
        }
        #if DEBUG
        if DebugLaunchOptions.seedsSampleData {
            try? SampleData.seed(into: modelContainer.mainContext)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(entitlements)
                .environment(\.locale, .japanese)
        }
        .modelContainer(modelContainer)
    }
}
