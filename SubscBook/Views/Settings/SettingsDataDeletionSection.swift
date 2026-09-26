import SwiftUI

/// データの全削除
struct SettingsDataDeletionSection: View {
    let viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(InsightProvider.self) private var insights
    @State private var isConfirming = false

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
                Button("すべて削除", role: .destructive) {
                    viewModel.deleteAllData(in: modelContext, insights: insights)
                }
            } message: {
                Text("登録したサブスクとチェックインの記録をすべて削除します。この操作は取り消せません。")
            }
        } footer: {
            Text("サブスク帳プラスの購読は削除されません。解約は「設定」アプリの「サブスクリプション」から行えます。")
        }
        .alert("データの全削除", isPresented: Binding(
            get: { viewModel.deletionMessage != nil },
            set: { if !$0 { viewModel.deletionMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(viewModel.deletionMessage ?? "")
        }
    }
}
