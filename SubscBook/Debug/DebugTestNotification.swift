#if DEBUG
import Foundation
import UserNotifications

/// UI テスト用：数秒後に届くチェックインの通知。終了した状態から通知で開いたときの動きを確かめるために使う。
enum DebugTestNotification {
    static let identifier = "debug.checkIn"

    /// 起動時の通知の登録し直し（登録済みをすべて消す）より後に登録するため、少し待ってから登録する
    static func schedule(registerAfter delay: Duration = .seconds(2), fireAfter interval: TimeInterval = 8) {
        Task {
            try? await Task.sleep(for: delay)
            let content = UNMutableNotificationContent()
            content.title = "月次チェックインの時間です"
            content.body = "（テスト）先月どのサブスクを使ったか、1件ずつ答えて振り返りましょう。"
            content.userInfo = [NotificationScheduler.kindKey: PlannedNotification.Kind.checkIn.rawValue]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            try? await UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            )
        }
    }
}
#endif
