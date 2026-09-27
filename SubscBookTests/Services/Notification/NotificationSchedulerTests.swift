import Foundation
import Testing
import UserNotifications
@testable import SubscBook

@Suite("通知の登録内容")
struct NotificationSchedulerTests {
    @Test("1回の通知は、年月日と時刻（分まで）で登録する")
    func onceTrigger() throws {
        let planned = PlannedNotification(
            identifier: "payment.x", kind: .payment, title: "明日は「Netflix」の支払日です",
            body: "1,590円（毎月）の支払いが予定されています。",
            trigger: .once(date(2026, 10, 14, 9)), subscriptionID: UUID()
        )
        let request = NotificationScheduler.request(for: planned, calendar: .tokyo)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(!trigger.repeats)
        #expect(trigger.dateComponents.year == 2026)
        #expect(trigger.dateComponents.month == 10)
        #expect(trigger.dateComponents.day == 14)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
        #expect(request.identifier == "payment.x")
        #expect(request.content.title == planned.title)
        #expect(request.content.userInfo[NotificationScheduler.kindKey] as? String == "payment")
        #expect(request.content.userInfo[NotificationScheduler.subscriptionIDKey] as? String == planned.subscriptionID?.uuidString)
    }

    @Test("月次チェックインは、毎月1日 20:00 に繰り返す")
    func monthlyTrigger() throws {
        let planned = PlannedNotification(
            identifier: "checkIn.monthly", kind: .checkIn, title: "月次チェックインの時間です", body: "",
            trigger: .monthly(day: NotificationPlanner.checkInDay, hour: NotificationPlanner.checkInHour)
        )
        let trigger = try #require(NotificationScheduler.request(for: planned).trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.day == 1)
        #expect(trigger.dateComponents.hour == 20)
        #expect(trigger.dateComponents.minute == 0)
        #expect(trigger.dateComponents.month == nil)
        // 次に届くのは、どこかの月の1日 20:00
        let next = try #require(trigger.nextTriggerDate())
        let parts = Calendar.current.dateComponents([.day, .hour, .minute], from: next)
        #expect(parts.day == 1 && parts.hour == 20 && parts.minute == 0)
    }
}
