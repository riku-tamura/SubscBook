#if DEBUG
import SwiftUI
import UserNotifications

/// 開発用：登録済みのローカル通知を確認する
struct DebugSettingsSection: View {
    @State private var requests: [UNNotificationRequest] = []

    var body: some View {
        Section("デバッグ") {
            NavigationLink("登録済みの通知（\(requests.count)件）") {
                List(requests, id: \.identifier) { request in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.content.title)
                            .font(.subheadline.weight(.semibold))
                        Text(request.content.body)
                            .font(.caption)
                        Text(triggerText(request.trigger))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("登録済みの通知")
            }
        }
        .task {
            requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
                .sorted { nextDate($0) < nextDate($1) }
        }
    }

    private func nextDate(_ request: UNNotificationRequest) -> Date {
        (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
    }

    private func triggerText(_ trigger: UNNotificationTrigger?) -> String {
        guard let trigger = trigger as? UNCalendarNotificationTrigger else { return "-" }
        let next = trigger.nextTriggerDate()?.formatted(.dateTime.year().month().day().hour().minute().locale(.japanese)) ?? "-"
        return trigger.repeats ? "毎月 \(next)〜" : next
    }
}
#endif
