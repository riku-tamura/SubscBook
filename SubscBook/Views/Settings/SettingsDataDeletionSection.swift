import SwiftData
import SwiftUI

/// データの全削除
struct SettingsDataDeletionSection: View {
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
            Text("サブスク帳プラスの購読は削除されません。解約は「設定」アプリの「サブスクリプション」から行えます。")
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
