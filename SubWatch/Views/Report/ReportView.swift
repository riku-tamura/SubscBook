import SwiftUI

/// ⑥ 振り返りレポート（Phase 4・6 で実装）
struct ReportView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("レポート", systemImage: "chart.pie", description: Text("準備中です"))
                .navigationTitle("レポート")
        }
    }
}
