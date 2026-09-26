import SwiftData
import SwiftUI

@main
struct SubWatchApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Subscription.self, CheckIn.self])
    }
}
