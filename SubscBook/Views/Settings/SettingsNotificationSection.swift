import SwiftUI

/// 通知の許可と、各通知の ON/OFF
struct SettingsNotificationSection: View {
    @AppStorage(NotificationPreferences.paymentReminderKey) private var paymentReminder = true
    @AppStorage(NotificationPreferences.trialReminderKey) private var trialReminder = true
    @AppStorage(NotificationPreferences.checkInReminderKey) private var checkInReminder = true
    @Environment(NotificationScheduler.self) private var notifications
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            switch notifications.authorizationStatus {
            case .notDetermined:
                Button("通知を許可する", systemImage: "bell.badge") {
                    Task { await notifications.requestAuthorization() }
                }
            case .denied:
                VStack(alignment: .leading, spacing: 8) {
                    Label("通知がオフになっています", systemImage: "bell.slash")
                        .foregroundStyle(.orange)
                    Text("支払日のお知らせを受け取るには、設定アプリで通知を許可してください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("設定アプリを開く") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
            default:
                EmptyView()
            }

            Toggle("支払日の前日（9:00）", isOn: $paymentReminder)

            if entitlements.isPremium {
                Toggle("無料トライアル終了（3日前・前日）", isOn: $trialReminder)
            } else {
                Button {
                    router.showPaywall(.lockedFeature(.trialReminders))
                } label: {
                    HStack {
                        Text("無料トライアル終了（3日前・前日）")
                        Spacer()
                        PremiumBadge()
                    }
                }
                .tint(.primary)
                .accessibilityLabel("無料トライアル終了のお知らせ。サブスク帳プラスで利用できます")
            }

            Toggle("月次チェックイン（毎月1日 20:00）", isOn: $checkInReminder)
        } header: {
            Text("通知")
        } footer: {
            Text("通知はこの端末の中だけで作成され、外部には送信されません。")
        }
        .task {
            await notifications.refreshAuthorizationStatus()
        }
        .onChange(of: paymentReminder) { notifications.reschedule() }
        .onChange(of: trialReminder) { notifications.reschedule() }
        .onChange(of: checkInReminder) { notifications.reschedule() }
    }
}
