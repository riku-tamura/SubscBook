import UIKit
import UserNotifications

/// 通知をタップしたときの画面遷移を受け持つ
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let router = AppRouter()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// アプリを開いている間もバナーを出す
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let kind = (response.notification.request.content.userInfo[NotificationScheduler.kindKey] as? String)
            .flatMap(PlannedNotification.Kind.init(rawValue:))
        await MainActor.run {
            router.openNotification(kind)
        }
    }
}
