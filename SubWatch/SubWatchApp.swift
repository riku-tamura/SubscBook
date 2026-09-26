import SwiftData
import SwiftUI

@main
struct SubWatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var entitlements: EntitlementManager
    @State private var notifications: NotificationScheduler
    private let modelContainer: ModelContainer

    init() {
        let modelContainer: ModelContainer
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
        let entitlements = EntitlementManager()
        self.modelContainer = modelContainer
        _entitlements = State(initialValue: entitlements)
        _notifications = State(initialValue: NotificationScheduler(modelContainer: modelContainer, entitlements: entitlements))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appDelegate.router)
                .environment(entitlements)
                .environment(notifications)
                .environment(\.locale, .japanese)
        }
        .modelContainer(modelContainer)
    }
}
