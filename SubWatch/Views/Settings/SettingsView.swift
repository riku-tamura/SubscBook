import SwiftUI

/// 設定（Phase 3・5・6 で実装）
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("設定", systemImage: "gearshape", description: Text("準備中です"))
                .navigationTitle("設定")
        }
    }
}
