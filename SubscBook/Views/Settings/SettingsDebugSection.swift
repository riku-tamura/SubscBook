#if DEBUG
import AdSupport
import AppTrackingTransparency
import SwiftUI
import UserNotifications

/// 開発用：プラスの切り替え、登録済みのローカル通知、広告 ID（AdMob のテストデバイスの登録用）
struct SettingsDebugSection: View {
    @State private var requests: [UNNotificationRequest] = []
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        @Bindable var entitlements = entitlements
        Section("デバッグ") {
            Toggle("プラスを有効にする（購入なし）", isOn: $entitlements.debugForcePremium)
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
                // 通知の設定を変えた後に開いても、今の状態を表示する
                .task { await loadRequests() }
            }
            // AdMob の「テストデバイス」に登録する ID。トラッキングを許可していないと、すべて0になる
            LabeledContent("広告 ID（IDFA）") {
                Text(advertisingIdentifier)
                    .font(.caption2.monospaced())
                    .textSelection(.enabled)
            }
            .accessibilityIdentifier("debug.advertisingIdentifier")
            Button("広告 ID をコピー") {
                UIPasteboard.general.string = advertisingIdentifier
            }
            .disabled(!isTrackingAuthorized)
        }
        .task { await loadRequests() }
    }

    private var isTrackingAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    private var advertisingIdentifier: String {
        guard isTrackingAuthorized else {
            return "トラッキングが許可されていません"
        }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }

    private func loadRequests() async {
        requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            .sorted { nextDate($0) < nextDate($1) }
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
