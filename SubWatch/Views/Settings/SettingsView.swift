import SwiftUI
import UserNotifications

/// 設定
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                NotificationSettingsSection()
                AISettingsSection()
                #if DEBUG
                DebugSettingsSection()
                #endif
            }
            .navigationTitle("設定")
        }
    }
}

/// 通知の許可と、各通知の ON/OFF
private struct NotificationSettingsSection: View {
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
                        PlusBadge()
                    }
                }
                .tint(.primary)
                .accessibilityLabel("無料トライアル終了のお知らせ。見張り番プラスで利用できます")
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

/// AIコメントの利用可否（非対応の場合は理由を表示）
private struct AISettingsSection: View {
    @Environment(InsightProvider.self) private var insights

    var body: some View {
        Section {
            LabeledContent("AIコメント") {
                Text(insights.availability.isAvailable ? "利用できます" : "テンプレートを表示中")
                    .foregroundStyle(insights.availability.isAvailable ? Color.green : .secondary)
            }
        } header: {
            Text("AI")
        } footer: {
            Text(insights.availability.message + "AIが使えない場合も、すべての機能をご利用いただけます。")
        }
    }
}
