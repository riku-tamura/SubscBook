#if DEBUG
import Foundation
import SwiftData
import UserNotifications

/// UI テスト用：アプリが実際に作る通知（支払日の前日・月次チェックイン）を、時刻だけ1〜2分後にずらして登録する。
/// 決まった時刻（9:00・毎月1日 20:00）まで待たずに、実機で本当に届くこと、タップしたときの画面の移り方を確かめるため。
/// 内容と登録の方法（UNCalendarNotificationTrigger）は、本番の通知と同じものを使う。
enum DebugTestNotification {
    static let identifierPrefix = "debug."

    /// 起動時の通知の登録し直し（登録済みをすべて消す）より後に登録するため、少し待ってから登録する
    static func schedule(from container: ModelContainer, registerAfter delay: Duration = .seconds(2)) {
        Task {
            try? await Task.sleep(for: delay)
            let subscriptions = (try? container.mainContext.fetch(
                FetchDescriptor(predicate: Subscription.activePredicate)
            )) ?? []
            let plan = NotificationPlanner.plan(subscriptions: subscriptions, isPremium: false, preferences: NotificationPreferences())
            // チェックインを先に、支払いを1分後に届ける
            let picked = [
                plan.first { $0.kind == .checkIn },
                plan.first { $0.kind == .payment },
            ].compactMap { $0 }

            let firstFireDate = nextWholeMinute(after: .now.addingTimeInterval(20))
            for (index, notification) in picked.enumerated() {
                let fireDate = firstFireDate.addingTimeInterval(Double(index) * 60)
                let shifted = PlannedNotification(
                    identifier: identifierPrefix + notification.identifier,
                    kind: notification.kind,
                    title: notification.title,
                    body: notification.body,
                    trigger: .once(fireDate),
                    subscriptionID: notification.subscriptionID
                )
                try? await UNUserNotificationCenter.current().add(NotificationScheduler.request(for: shifted))
            }
        }
    }

    /// 通知は分の単位で届くので、次のちょうどの分にそろえる
    private static func nextWholeMinute(after date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.dateInterval(of: .minute, for: date)!.start
        return calendar.date(byAdding: .minute, value: 1, to: start)!
    }
}
#endif
