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
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    /// 通知をタップしたときの遷移。完了の知らせ（completionHandler）はメインスレッドで呼ぶ。
    /// async 版を使うと、アプリが起動していないときに通知から開くと、完了の知らせがメインスレッド以外から
    /// 呼ばれて UIKit のチェックで落ちる（起動中は再現しない）ため、completionHandler 版にしている。
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let kind = (response.notification.request.content.userInfo[NotificationScheduler.kindKey] as? String)
            .flatMap(PlannedNotification.Kind.init(rawValue:))
        // UIKit の完了の知らせは、メインスレッドで呼べば安全（Sendable と宣言されていないだけ）
        nonisolated(unsafe) let completion = completionHandler
        Task { @MainActor in
            router.openNotification(kind)
            completion()
        }
    }
}
