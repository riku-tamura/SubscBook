import StoreKit
import SwiftData
import SwiftUI
import UserNotifications

/// 設定
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                PremiumSettingsSection()
                NotificationSettingsSection()
                AISettingsSection()
                AboutSection()
                DataDeletionSection()
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

/// 見張り番プラスの状態・管理・購入の復元
private struct PremiumSettingsSection: View {
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @State private var isManagingSubscription = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    var body: some View {
        Section {
            if entitlements.isPremium {
                LabeledContent("ご利用中", value: planName)
                if let plan = entitlements.activePlan {
                    if plan.isInFreeTrial {
                        LabeledContent("状態", value: "無料トライアル中")
                    }
                    if let expirationDate = plan.expirationDate {
                        LabeledContent(plan.willAutoRenew ? "次回の更新日" : "有効期限", value: expirationDate.fullDateText)
                    }
                }
                Button("サブスクリプションを管理") {
                    isManagingSubscription = true
                }
            } else {
                Button {
                    router.showPaywall(.settings)
                } label: {
                    HStack {
                        Label("見張り番プラスにアップグレード", systemImage: "star.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Button {
                Task { await restore() }
            } label: {
                HStack {
                    Text("購入を復元")
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
        } header: {
            Text("見張り番プラス")
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        .alert("購入の復元", isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    private var planName: String {
        guard let plan = entitlements.activePlan else { return "見張り番プラス" }
        return plan.isYearly ? "年額プラン" : "月額プラン"
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlements.restore()
            restoreMessage = entitlements.isPremium
                ? "見張り番プラスの購入を復元しました。"
                : "この Apple ID で見張り番プラスの購入が見つかりませんでした。"
        } catch {
            restoreMessage = "復元できませんでした。時間をおいて、もう一度お試しください。"
        }
    }
}

/// 利用規約・プライバシーポリシー・バージョン
private struct AboutSection: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(version)（\(build)）"
    }

    var body: some View {
        Section("このアプリについて") {
            Link(destination: AppLinks.termsOfUse) {
                HStack {
                    Text("利用規約")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .tint(.primary)
            NavigationLink("プライバシーポリシー") {
                PrivacyPolicyView()
            }
            LabeledContent("バージョン", value: version)
        }
    }
}

/// データの全削除
private struct DataDeletionSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationScheduler.self) private var notifications
    @Environment(InsightProvider.self) private var insights
    @State private var isConfirming = false
    @State private var resultMessage: String?

    var body: some View {
        Section {
            Button("データの全削除", role: .destructive) {
                isConfirming = true
            }
            .confirmationDialog(
                "すべてのデータを削除しますか？",
                isPresented: $isConfirming,
                titleVisibility: .visible
            ) {
                Button("すべて削除", role: .destructive, action: deleteAll)
            } message: {
                Text("登録したサブスクとチェックインの記録をすべて削除します。この操作は取り消せません。")
            }
        } footer: {
            Text("見張り番プラスの購読は削除されません。解約は「設定」アプリの「サブスクリプション」から行えます。")
        }
        .alert("データの全削除", isPresented: Binding(
            get: { resultMessage != nil },
            set: { if !$0 { resultMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private func deleteAll() {
        do {
            // @Query の表示が確実に更新されるよう、1件ずつ削除する（チェックインは連鎖して消える）
            for subscription in try modelContext.fetch(FetchDescriptor<Subscription>()) {
                modelContext.delete(subscription)
            }
            for checkIn in try modelContext.fetch(FetchDescriptor<CheckIn>()) {
                modelContext.delete(checkIn)
            }
            try modelContext.save()
            insights.clearCache()
            notifications.reschedule()
            resultMessage = "すべてのデータを削除しました。"
        } catch {
            resultMessage = "削除できませんでした。もう一度お試しください。"
        }
    }
}
