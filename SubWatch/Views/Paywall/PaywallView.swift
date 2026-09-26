import SwiftUI

/// ⑦ ペイウォール（Phase 5 で実装）
struct PaywallView: View {
    let reason: PaywallReason
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView("見張り番プラス", systemImage: "star.circle", description: Text("準備中です"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { dismiss() }
                    }
                }
        }
    }
}
